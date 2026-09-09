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

    public func reset() {
        for key in [Key.retentionPolicy, Key.hasCompletedOnboarding, Key.lastPurgeAt, Key.saveCount] {
            defaults.removeObject(forKey: key)
        }
    }
}
