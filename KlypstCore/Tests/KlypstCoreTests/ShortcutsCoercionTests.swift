import Testing
@testable import KlypstCore

@Suite("ShortcutsCoercion")
struct ShortcutsCoercionTests {
    private let textOnly = ClipboardAvailability(hasText: true, hasImage: false)
    private let imageOnly = ClipboardAvailability(hasText: false, hasImage: true)
    private let both = ClipboardAvailability(hasText: true, hasImage: true)

    @Test func keepsRealText() {
        #expect(ShortcutsCoercion.textToSave("  39 delhi road, north \n", clipboard: textOnly) == "39 delhi road, north")
        #expect(ShortcutsCoercion.textToSave("https://sprint.buildclub.ai/", clipboard: textOnly) == "https://sprint.buildclub.ai/")
        let sentence = "Joe and Angela's marriage is on thin ice. When their upstairs neighbors visit for a dinner party, the night spirals."
        #expect(ShortcutsCoercion.textToSave(sentence, clipboard: both) == sentence)
    }

    @Test func dropsEmpty() {
        #expect(ShortcutsCoercion.textToSave(" \n", clipboard: textOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("", clipboard: imageOnly) == nil)
    }

    @Test func dropsAnythingWhenTheClipboardIsAnImageOnly() {
        #expect(ShortcutsCoercion.textToSave("Clipboard 11 Sep 2026 at 2.33.28 pm.png", clipboard: imageOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("Klypst Clip", clipboard: imageOnly) == nil)
        #expect(ShortcutsCoercion.textToSave("anything at all", clipboard: imageOnly) == nil)
    }

    @Test func dropsGeneratedNamesWhenTheClipboardHasTextToo() {
        for name in [
            "Clipboard 11 Sep 2026 at 2.33.28 pm.png",
            "Clipboard 11 Sep 2026 at 2.33 pm",     // no extension: the case that slipped through
            "Klypst Clip",
            "Klypst Clip.png",
            "IMG_5077",
            "Screenshot 2026-09-11 at 2.33.28 pm",
            "Pasted Image",
        ] {
            #expect(ShortcutsCoercion.textToSave(name, clipboard: both) == nil, "should drop \(name)")
        }
    }

    @Test func keepsProseThatMerelyResemblesAName() {
        for text in [
            "Send me logo.png when you can",
            "Clipboard managers are having a moment, and here is why that matters for iPhone users",
            "line one\nClipboard 11 Sep 2026",
            "Image quality was terrible on the trailer",
        ] {
            #expect(ShortcutsCoercion.textToSave(text, clipboard: both) == text, "should keep \(text)")
        }
    }

    @Test func keepsTextWhenTheClipboardStateIsUnknown() {
        #expect(ShortcutsCoercion.textToSave("Klypst Clip.png") == "Klypst Clip.png")
    }
}
