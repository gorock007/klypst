import Foundation

/// Guards against Shortcuts' type coercion. When the Clipboard variable holds an image
/// but the shortcut wires it into a text parameter, Shortcuts substitutes a name for the
/// item — "Clipboard 11 Sep 2026 at 2.33 pm" (with or without an extension), "Klypst
/// Clip.png" for an image Klypst wrote, "IMG_5077" straight from Photos. Saving any of
/// those as a text clip is never right.
public enum ShortcutsCoercion {
    /// Names Shortcuts and Photos generate. Each is anchored and single-line, so it can
    /// only ever match a short bare name, never a sentence or a multi-line snippet.
    /// Names Shortcuts and Photos generate. Every pattern is anchored at both ends and
    /// demands the shape of a bare name — a date or number after the word, or an exact
    /// literal — so prose that merely opens with "Clipboard" or "Image" is left alone.
    private static let generatedNamePatterns = [
        #"^.{1,120}\.(png|jpe?g|heic|heif|gif|tiff?|webp|bmp)$"#,   // any image file name
        #"^Clipboard \d.{0,80}$"#,                                  // Clipboard 11 Sep 2026 at 2.33 pm
        #"^Screenshot \d.{0,80}$"#,                                 // Screenshot 2026-09-11 at 2.33 pm
        #"^Klypst Clip$"#,                                          // our own IntentFile name
        #"^IMG[_-]?\d{1,6}$"#,                                      // IMG_5077
        #"^(Photo|Image|Pasted Image)$"#,
    ]

    /// The text worth saving, or nil when it is empty or a name Shortcuts invented for an image.
    ///
    /// Deliberately judged from the string alone. `UIPasteboard`'s `has*` flags look like a
    /// better signal, but they are not dependable from an intent running in the background,
    /// which is exactly when this runs. The caller's real defence is to ignore this string
    /// entirely whenever Shortcuts also handed over an image.
    public static func textToSave(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return looksLikeGeneratedImageName(text) ? nil : text
    }

    /// True when the string is a bare, single-line name of the kind the system invents
    /// for an image, rather than something a person copied.
    public static func looksLikeGeneratedImageName(_ text: String) -> Bool {
        guard !text.contains("\n"), text.count <= 120 else { return false }
        return generatedNamePatterns.contains {
            text.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
}
