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

    public func reset() {
        for key in [
            Key.retentionPolicy, Key.hasCompletedOnboarding, Key.lastPurgeAt, Key.saveCount,
            Key.lastSeenPasteboardChangeCount, Key.allowsUniversalClipboard, Key.pasteboardExpiry,
        ] {
            defaults.removeObject(forKey: key)
        }
    }
}
