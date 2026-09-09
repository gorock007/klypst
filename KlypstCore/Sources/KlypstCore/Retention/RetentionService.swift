import Foundation

/// Opportunistic retention. Runs on launch/foreground/after saves; never a
/// perpetual background job (architecture §14).
public struct RetentionService: Sendable {
    public let repository: any ClipRepository
    public let preferences: PreferencesStore
    public let minimumInterval: TimeInterval

    public init(repository: any ClipRepository, preferences: PreferencesStore, minimumInterval: TimeInterval = 10 * 60) {
        self.repository = repository
        self.preferences = preferences
        self.minimumInterval = minimumInterval
    }

    /// Purges expired clips if the last run was longer than `minimumInterval` ago.
    @discardableResult
    public func runIfNeeded(force: Bool = false, now: Date = .now) async -> Int {
        if !force, let last = preferences.lastPurgeAt, now.timeIntervalSince(last) < minimumInterval {
            return 0
        }
        do {
            let purged = try await repository.purgeExpired(policy: preferences.retentionPolicy)
            preferences.lastPurgeAt = now
            return purged
        } catch {
            KlypstLog.retention.error("Retention run failed: \(String(describing: type(of: error)), privacy: .public)")
            return 0
        }
    }
}
