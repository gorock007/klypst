import Foundation

/// What the general pasteboard is holding, from `UIPasteboard`'s `has*` flags only.
/// Those flags are metadata: reading them never triggers the system paste notice.
public struct ClipboardAvailability: Sendable, Hashable {
    public let hasText: Bool
    public let hasImage: Bool

    public init(hasText: Bool, hasImage: Bool) {
        self.hasText = hasText
        self.hasImage = hasImage
    }

    public static let unknown = ClipboardAvailability(hasText: true, hasImage: false)
}

/// Guards against Shortcuts' type coercion. When the Clipboard variable holds an image
/// but the shortcut wires it into a text parameter, Shortcuts substitutes the item's
/// file name — "Clipboard 11 Sep 2026 at 2.04.png" for a photo, "Klypst Clip.png" for
/// one Klypst wrote itself. Saving that as a text clip is never right.
public enum ShortcutsCoercion {
    private static let imageFileNamePattern = #"^[^\n]{1,120}\.(png|jpe?g|heic|heif|gif|tiff?|webp|bmp)$"#

    /// The text worth saving, or nil when it is empty or a coerced image file name.
    ///
    /// The pasteboard flags decide, not the string: if the clipboard holds an image and
    /// no text at all, any string that arrived is an artifact. When it holds both, only a
    /// bare image file name is rejected, so real text is never silently dropped.
    public static func textToSave(_ raw: String, clipboard: ClipboardAvailability = .unknown) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard clipboard.hasImage else { return text }
        if !clipboard.hasText { return nil }
        if text.range(of: imageFileNamePattern, options: [.regularExpression, .caseInsensitive]) != nil { return nil }
        return text
    }
}
