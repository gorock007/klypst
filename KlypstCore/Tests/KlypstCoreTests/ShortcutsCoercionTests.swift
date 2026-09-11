import Testing
@testable import KlypstCore

@Suite("ShortcutsCoercion")
struct ShortcutsCoercionTests {
    @Test func keepsRealText() {
        #expect(ShortcutsCoercion.textToSave("  39 delhi road, north \n") == "39 delhi road, north")
        #expect(ShortcutsCoercion.textToSave("https://apple.com") == "https://apple.com")
        #expect(ShortcutsCoercion.textToSave("Clipboard notes for Monday") == "Clipboard notes for Monday")
    }

    @Test func dropsEmptyAndPlaceholderNames() {
        #expect(ShortcutsCoercion.textToSave(" \n") == nil)
        #expect(ShortcutsCoercion.textToSave("Clipboard 11 Sep 2026 at 12.23.png") == nil)
        #expect(ShortcutsCoercion.textToSave("Clipboard 11 Sep 2026 at 12.23.01.HEIC") == nil)
        #expect(ShortcutsCoercion.textToSave("Clipboard 2026-09-11 at 12.23.jpeg") == nil)
    }
}
