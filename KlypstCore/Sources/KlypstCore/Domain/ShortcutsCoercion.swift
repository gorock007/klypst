import Foundation

/// Guards against Shortcuts' type coercion when the Clipboard variable holds an image
/// but lands in a text parameter: Shortcuts substitutes the item's placeholder file
/// name ("Clipboard 11 Sep 2026 at 12.23.png"). That is never something to keep.
public enum ShortcutsCoercion {
    private static let placeholderPattern = #"^Clipboard .+\.(png|jpe?g|heic|heif|gif|tiff?|webp|bmp)$"#

    /// The text worth saving, or nil when it is empty or a coerced image placeholder.
    public static func textToSave(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text.range(of: placeholderPattern, options: [.regularExpression, .caseInsensitive]) != nil { return nil }
        return text
    }
}
