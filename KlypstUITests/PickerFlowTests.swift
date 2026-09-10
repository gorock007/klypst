import XCTest

/// Drives the real Pick a Clip card through Spotlight (debug-only App Shortcut).
/// Opt-in: `TEST_RUNNER_KLYPST_SYSTEM_UI=1 xcodebuild test ...`. Run it on a device:
/// in the iOS 26.5 simulator, Spotlight lists App Shortcuts but the Shortcuts
/// backend fails every one with "Couldn't find shortcut".
/// Screenshots go to the directory in `KLYPST_SCREENSHOT_DIR` when set.
@MainActor
final class PickerFlowTests: XCTestCase {
    private var springboard: XCUIApplication!

    override func setUpWithError() throws {
        springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        try XCTSkipUnless(ProcessInfo.processInfo.environment["KLYPST_SYSTEM_UI"] == "1", "System UI test; set TEST_RUNNER_KLYPST_SYSTEM_UI=1")
        continueAfterFailure = false
    }

    func testPickerCardSelectsAndContinues() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset-state", "--skip-onboarding", "--seed-sample-clips"]
        app.launch()
        XCTAssertTrue(app.staticTexts["https://naatiace.com/"].waitForExistence(timeout: 10), "Sample clips were not seeded")
        // Give the system time to register this install's App Shortcuts.
        sleep(UInt32(ProcessInfo.processInfo.environment["KLYPST_REGISTRATION_WAIT"].flatMap(Int.init) ?? 20))

        XCUIDevice.shared.press(.home)
        openSpotlight()
        let spotlight = XCUIApplication(bundleIdentifier: "com.apple.Spotlight")
        let query = ProcessInfo.processInfo.environment["KLYPST_SPOTLIGHT_QUERY"] ?? "Pick a Clip"
        spotlight.typeText(query)
        sleep(3)

        let topHit = spotlight.staticTexts["Top Hit"]
        XCTAssertTrue(topHit.waitForExistence(timeout: 15), "App Shortcut not found in Spotlight")
        save("01-spotlight")
        spotlight.typeText("\n") // Go runs the top hit.

        sleep(4)
        save("02-card")
        // The snippet is hosted by whichever system process ran the intent.
        let host: XCUIApplication = [springboard!, spotlight].first {
            $0.staticTexts["Pick a clip to copy"].waitForExistence(timeout: 5)
        } ?? springboard!
        let header = host.staticTexts["Pick a clip to copy"]
        XCTAssertTrue(header.exists, "Picker card did not appear")

        let meeting = host.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Meeting notes")).firstMatch
        XCTAssertTrue(meeting.exists)
        meeting.tap()
        sleep(2)
        save("03-selected")

        let cont = host.buttons["Continue"]
        XCTAssertTrue(cont.waitForExistence(timeout: 5), "Continue button missing")
        cont.tap()
        sleep(2)
        save("04-after-continue")
        XCTAssertFalse(header.exists, "Card should close after Continue")
    }

    private func openSpotlight() {
        sleep(1)
        let search = springboard.buttons["Search"]
        if search.waitForExistence(timeout: 3) {
            search.tap()
        } else {
            springboard.swipeDown()
        }
        sleep(2)
        save("00-spotlight-open")
    }

    private func save(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["KLYPST_SCREENSHOT_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appending(path: "\(name).png"))
        }
    }
}
