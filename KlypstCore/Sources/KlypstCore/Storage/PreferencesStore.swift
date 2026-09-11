import Foundation

/// Small, non-sensitive preferences in the App Group `UserDefaults` suite.
///
/// Never store clip bodies here (architecture §7).
public struct PreferencesStore: Sendable {
    public enum Key {
        public static let retentionPolicy = "retentionPolicy"
        public static let hasCompletedOnboarding = "hasCompletedOnboarding"
        public static let lastPurgeAt = "lastPurgeAt"
        public static let saveCount = "saveCount"
        public static let lastSeenPasteboardChangeCount = "lastSeenPasteboardChangeCount"
        public static let allowsUniversalClipboard = "allowsUniversalClipboard"
        public static let pasteboardExpiry = "pasteboardExpiry"
        public static let captureTrigger = "captureTrigger"
        public static let setupShortcutAdded = "setupShortcutAdded"
        public static let setupTriggerAssigned = "setupTriggerAssigned"
        public static let shortcutRunCount = "shortcutRunCount"
        public static let lastShortcutRunAt = "lastShortcutRunAt"
        public static let hasDismissedSetupCard = "hasDismissedSetupCard"
    }

    private let suiteName: String?

    public init(suiteName: String? = KlypstConfiguration.appGroupIdentifier) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        if let suiteName, let suite = UserDefaults(suiteName: suiteName) { return suite }
        return .standard
    }

    public var retentionPolicy: RetentionPolicy {
        get {
            guard defaults.object(forKey: Key.retentionPolicy) != nil else { return .default }
            return RetentionPolicy(rawValue: defaults.integer(forKey: Key.retentionPolicy)) ?? .default
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.retentionPolicy) }
    }

    public var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Key.hasCompletedOnboarding) }
        nonmutating set { defaults.set(newValue, forKey: Key.hasCompletedOnboarding) }
    }

    public var lastPurgeAt: Date? {
        get { defaults.object(forKey: Key.lastPurgeAt) as? Date }
        nonmutating set { defaults.set(newValue, forKey: Key.lastPurgeAt) }
    }

    /// `UIPasteboard.general.changeCount` the last time Klypst saved, copied or the user dismissed the nudge.
    /// Reading the change count never triggers the system paste notice.
    public var lastSeenPasteboardChangeCount: Int {
        get { defaults.object(forKey: Key.lastSeenPasteboardChangeCount) as? Int ?? -1 }
        nonmutating set { defaults.set(newValue, forKey: Key.lastSeenPasteboardChangeCount) }
    }

    /// When false (the default), clips copied from Klypst are written `localOnly` and never
    /// leave this device through Universal Clipboard.
    public var allowsUniversalClipboard: Bool {
        get { defaults.bool(forKey: Key.allowsUniversalClipboard) }
        nonmutating set { defaults.set(newValue, forKey: Key.allowsUniversalClipboard) }
    }

    /// How long a clip copied from Klypst stays on the pasteboard before iOS clears it.
    public var pasteboardExpiry: PasteboardExpiry {
        get {
            guard defaults.object(forKey: Key.pasteboardExpiry) != nil else { return .default }
            return PasteboardExpiry(rawValue: defaults.integer(forKey: Key.pasteboardExpiry)) ?? .default
        }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.pasteboardExpiry) }
    }

    /// The options every pasteboard write should use, derived from the two settings above.
    public var pasteboardWriteOptions: PasteboardWriteOptions {
        PasteboardWriteOptions(isLocalOnly: !allowsUniversalClipboard, expiry: pasteboardExpiry)
    }

    // MARK: First-run setup

    /// The trigger the person chose for the Klypst shortcut.
    public var captureTrigger: CaptureTrigger {
        get { CaptureTrigger(rawValue: defaults.string(forKey: Key.captureTrigger) ?? "") ?? .undecided }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.captureTrigger) }
    }

    /// Set when the person hands the shortcut file to Shortcuts (or marks it done).
    public var setupShortcutAdded: Bool {
        get { defaults.bool(forKey: Key.setupShortcutAdded) }
        nonmutating set { defaults.set(newValue, forKey: Key.setupShortcutAdded) }
    }

    /// Set when the person marks the trigger as assigned in Settings.
    public var setupTriggerAssigned: Bool {
        get { defaults.bool(forKey: Key.setupTriggerAssigned) }
        nonmutating set { defaults.set(newValue, forKey: Key.setupTriggerAssigned) }
    }

    /// How many times a Klypst picker shortcut has run on this device. Written by the
    /// picker intents, which run inside the app process; proof that setup works.
    public var shortcutRunCount: Int {
        get { defaults.integer(forKey: Key.shortcutRunCount) }
        nonmutating set { defaults.set(newValue, forKey: Key.shortcutRunCount) }
    }

    public var lastShortcutRunAt: Date? {
        get { defaults.object(forKey: Key.lastShortcutRunAt) as? Date }
        nonmutating set { defaults.set(newValue, forKey: Key.lastShortcutRunAt) }
    }

    /// The "Finish setting up" card in History was dismissed with Later.
    public var hasDismissedSetupCard: Bool {
        get { defaults.bool(forKey: Key.hasDismissedSetupCard) }
        nonmutating set { defaults.set(newValue, forKey: Key.hasDismissedSetupCard) }
    }

    public func recordShortcutRun(at date: Date = .now) {
        shortcutRunCount += 1
        lastShortcutRunAt = date
    }

    public var setupProgress: SetupProgress {
        SetupProgress(
            shortcutAdded: setupShortcutAdded,
            triggerAssigned: setupTriggerAssigned,
            hasRun: shortcutRunCount > 0,
            trigger: captureTrigger
        )
    }

    public func reset() {
        for key in [
            Key.retentionPolicy, Key.hasCompletedOnboarding, Key.lastPurgeAt, Key.saveCount,
            Key.lastSeenPasteboardChangeCount, Key.allowsUniversalClipboard, Key.pasteboardExpiry,
            Key.captureTrigger, Key.setupShortcutAdded, Key.setupTriggerAssigned,
            Key.shortcutRunCount, Key.lastShortcutRunAt, Key.hasDismissedSetupCard,
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}
