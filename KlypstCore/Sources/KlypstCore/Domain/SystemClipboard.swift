import Foundation

/// Access to the system general pasteboard.
///
/// Reads happen only on explicit, user-initiated paths. There is no polling and
/// no read-on-foreground. See architecture §9.
public protocol SystemClipboard: Sendable {
    /// What the pasteboard holds, from metadata flags only. Never triggers the paste notice.
    @MainActor func availability() -> ClipboardAvailability
    /// Reads the single best representation currently on the pasteboard.
    /// Returns nil when the pasteboard holds nothing we support.
    @MainActor func readUserInitiatedContent() async throws -> ClipInput?
    /// Writes a stored clip back to the general pasteboard.
    @MainActor func write(_ content: ClipContent, options: PasteboardWriteOptions) throws
    /// Writes plain text (for example several clips joined together) to the general pasteboard.
    @MainActor func writeText(_ text: String, options: PasteboardWriteOptions) throws
}

public enum SystemClipboardError: Error, Sendable {
    case payloadMissing
}
