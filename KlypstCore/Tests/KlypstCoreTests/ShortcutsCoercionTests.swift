import Testing
@testable import KlypstCore

@Suite("ShortcutsCoercion")
struct ShortcutsCoercionTests {
    @Test func keepsRealText() {
        #expect(ShortcutsCoercion.textToSave("  39 delhi road, north \n") == "39 delhi road, north")
        #expect(ShortcutsCoercion.textToSave("https://sprint.buildclub.ai/") == "https://sprint.buildclub.ai/")
        let sentence = "Joe and Angela's marriage is on thin ice. When their upstairs neighbors visit, the night spirals."
        #expect(ShortcutsCoercion.textToSave(sentence) == sentence)
    }

    @Test func dropsEmpty() {
        #expect(ShortcutsCoercion.textToSave(" \n") == nil)
        #expect(ShortcutsCoercion.textToSave("") == nil)
    }

    @Test func dropsGeneratedImageNames() {
        for name in [
            "Clipboard 11 Sep 2026 at 2.33.28 pm.png",
            "Clipboard 11 Sep 2026 at 2.33 pm",     // no extension: the case seen on device
            "Klypst Clip",
            "Klypst Clip.png",
            "IMG_5077",
            "Screenshot 2026-09-11 at 2.33.28 pm",
            "Pasted Image",
        ] {
            #expect(ShortcutsCoercion.textToSave(name) == nil, "should drop \(name)")
        }
    }

    @Test func keepsProseThatMerelyResemblesAName() {
        for text in [
            "Send me logo.png when you can",
            "Clipboard managers are having a moment, and here is why that matters for iPhone users",
            "line one\nClipboard 11 Sep 2026",
            "Image quality was terrible on the trailer",
            "Screenshot the error and send it over",
        ] {
            #expect(ShortcutsCoercion.textToSave(text) == text, "should keep \(text)")
        }
    }
}
