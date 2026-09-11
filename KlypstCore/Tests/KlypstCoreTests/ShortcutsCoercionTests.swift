import Testing
@testable import KlypstCore

@Suite("ShortcutsCoercion")
struct ShortcutsCoercionTests {
    private let textOnly = ClipboardAvailability(hasText: true, hasImage: false)
    private let imageOnly = ClipboardAvailability(hasText: false, hasImage: true)
    private let both = ClipboardAvailability(hasText: true, hasImage: true)

    @Test func keepsRealText() {
        #expect(ShortcutsCoercion.textToSave("  39 delhi road, north \n", clipboard: textOnly) == "39 delhi road, north")
        #expect(ShortcutsCoercion.textToSave("https://apple.com", clipboard: textOnly) == "https://apple.com")
        #expect(ShortcutsCoercion.textToSave("Clipboard notes for Monday", clipboard: textOnly) == "Clipboard notes for Monday")
    }

    @Test func dropsEmpty() {
        #expect(ShortcutsCoercion.textToSave(" \n", clipboard: textOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("", clipboard: imageOnly) == nil)
    }

    @Test func dropsAnythingWhenTheClipboardIsAnImageOnly() {
        // Whatever Shortcuts substituted, it isn't text the user copied.
        #expect(ShortcutsCoercion.textToSave("Clipboard 11 Sep 2026 at 2.04.png", clipboard: imageOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("Klypst Clip", clipboard: imageOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("IMG_5077", clipboard: imageOnly) == nil)
    }

    @Test func dropsOnlyFileNamesWhenTheClipboardHasTextToo() {
        #expect(ShortcutsCoercion.textToSave("Klypst Clip.png", clipboard: both) == nil)
        #expect(ShortcutsCoercion.textToSave("Clipboard 11 Sep 2026 at 2.04.HEIC", clipboard: both) == nil)
        // Real text survives, including text that merely mentions a file.
        #expect(ShortcutsCoercion.textToSave("Send me logo.png when you can", clipboard: both) == "Send me logo.png when you can")
        #expect(ShortcutsCoercion.textToSave("line one\nlogo.png", clipboard: both) == "line one\nlogo.png")
    }

    @Test func keepsTextWhenTheClipboardStateIsUnknown() {
        #expect(ShortcutsCoercion.textToSave("Klypst Clip.png") == "Klypst Clip.png")
    }
}
