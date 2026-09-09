import Foundation

/// The narrow persistence boundary every target talks to.
///
/// Implementations must be safe to use from the app, the Share Extension and
/// App Intents concurrently: the store lives in the shared App Group container.
public protocol ClipRepository: Sendable {
    func recent(limit: Int) async throws -> [ClipSummary]
    func pinned(limit: Int) async throws -> [ClipSummary]
    func search(_ query: String, pinnedOnly: Bool, limit: Int) async throws -> [ClipSummary]
    func clip(id: UUID) async throws -> ClipContent?
    func save(_ input: ClipInput) async throws -> SaveResult
    func markUsed(id: UUID) async throws
    func setPinned(id: UUID, _ pinned: Bool) async throws
    func delete(id: UUID) async throws
    func deleteAll() async throws
    /// Deletes unpinned clips last used before the policy cutoff, and removes orphaned payload files.
    @discardableResult
    func purgeExpired(policy: RetentionPolicy) async throws -> Int
    func count() async throws -> Int
}

public enum ClipRepositoryError: Error, Sendable, Equatable {
    case notFound
    case storeUnavailable
}
