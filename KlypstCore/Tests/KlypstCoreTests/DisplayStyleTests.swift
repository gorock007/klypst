import Foundation
import Testing
@testable import KlypstCore

@Suite("ClipDisplayStyle")
struct DisplayStyleTests {
    @Test(arguments: [
        "npm install klypst",
        "git push origin main",
        "$ ls -la",
        "brew install --cask xcodes",
        "const total = items.reduce((a, b) => a + b, 0)",
        "func load() async throws {",
        "let x = 5",
        "import SwiftUI",
        "if (a == b && c) { run(); }",
        "SELECT * FROM clips WHERE id = 1;",
        "<div class=\"row\"></div>",
    ])
    func detectsCode(_ sample: String) {
        #expect(ClipDisplayStyle(kind: .text, preview: sample) == .code)
    }

    @Test(arguments: [
        "Meeting notes about Q3 planning",
        "let me know when you land",
        "Import the photos from last week",
        "Go to the store and get milk",
        "Call me at 0412 345 678",
        "Pick up keys (the spare set) from Sam",
        "42 Wallaby Way, Sydney NSW 2000",
        "Swift is a great language",
        "Select the blue one, not the red one",
        "Update: the flight is delayed",
        "import tariffs are rising again next year",
        "<3 see you soon",
        "var",
        "",
    ])
    func leavesProseAlone(_ sample: String) {
        #expect(ClipDisplayStyle(kind: .text, preview: sample) == .text)
    }

    @Test func mapsStoredKinds() {
        #expect(ClipDisplayStyle(kind: .url, preview: "https://apple.com") == .link)
        #expect(ClipDisplayStyle(kind: .image, preview: "Image") == .image)
        #expect(ClipDisplayStyle.code.displayName == "Code")
    }
}
