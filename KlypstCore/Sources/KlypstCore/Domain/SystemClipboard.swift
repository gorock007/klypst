import Foundation

/// Access to the system general pasteboard.
///
/// Reads happen only on explicit, user-initiated paths. There is no polling and
/// no read-on-foreground. See architecture §9.
public protocol SystemClipboard: Sendable {
    /// Reads the single best representation currently on the pasteboard.
    /// Returns nil when the pasteboard holds nothing we support.
    @MainActor func readUserInitiatedContent() async throws -> ClipInput?
    /// Writes a stored clip back to the general pasteboard.
    @MainActor func write(_ content: ClipContent) throws
}

public enum SystemClipboardError: Error, Sendable {
    case payloadMissing
}
