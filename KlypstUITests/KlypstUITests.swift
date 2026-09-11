import UIKit
import XCTest

/// Smoke tests for the core loop: save the clipboard → see it → copy it back.
@MainActor
final class KlypstUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--reset-state"]
    }

    private func launchPastOnboarding() {
        app.launch()
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 5) { skip.tap() }
        snap("01-after-skip")
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
    }

    private func toast(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "toast")
            .containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// Saves a screenshot next to the test results, and to `KLYPST_SNAP_DIR` when set.
    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        if let dir = ProcessInfo.processInfo.environment["KLYPST_SNAP_DIR"] {
            try? shot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }

    func testSaveClipboardShowsClipAndCopiesItBack() {
        let text = "Klypst UI test \(Int(Date().timeIntervalSince1970))"
        UIPasteboard.general.string = text
        launchPastOnboarding()

        app.buttons["Save Clipboard"].firstMatch.tap()
        // iOS may ask for paste permission the first time (system alert, owned by SpringBoard).
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow Paste"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
        snap("02-after-save")

        let row = app.staticTexts[text]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Saved clip should appear in History")
        snap("03-row")

        // Saving the same content again dedupes.
        app.buttons["Save Clipboard"].firstMatch.tap()
        let duplicateToast = toast(containing: "Already saved")
        if !duplicateToast.waitForExistence(timeout: 2), allow.exists {
            allow.tap()
            XCTAssertTrue(duplicateToast.waitForExistence(timeout: 3))
        }
        snap("03b-second-save")
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label == %@", text)).count, 1)

        // Open detail and copy it back after clearing the pasteboard.
        UIPasteboard.general.string = "something else"
        row.tap()
        snap("04-detail")
        let copyButton = app.buttons["Copy"].firstMatch
        XCTAssertTrue(copyButton.waitForExistence(timeout: 3))
        copyButton.tap()
        XCTAssertTrue(toast(containing: "Copied").waitForExistence(timeout: 3))
        snap("05-copied")

        // Verify through the app rather than reading the pasteboard from the test runner,
        // which would trigger the system paste-permission alert. If Copy put the original
        // text back on the pasteboard, saving again dedupes; otherwise "something else" is saved.
        app.buttons["BackButton"].tap()
        app.buttons["Save Clipboard"].firstMatch.tap()
        XCTAssertTrue(toast(containing: "Already saved").waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["something else"].exists)
        snap("06-verified")
    }

    func testEmptyStateAndSettings() {
        launchPastOnboarding()
        XCTAssertTrue(app.staticTexts["Nothing here yet."].waitForExistence(timeout: 5))

        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        snap("06-settings")
        // The Privacy section sits below Retention and Copying; lists only realize rows on screen.
        let storageRow = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "On this device only")).firstMatch
        var swipes = 0
        while !storageRow.exists, swipes < 4 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(storageRow.exists)
        let privacyPolicy = app.buttons["Privacy Policy"].firstMatch
        XCTAssertTrue(privacyPolicy.waitForExistence(timeout: 3))
        privacyPolicy.tap()
        XCTAssertTrue(app.navigationBars["Privacy Policy"].waitForExistence(timeout: 5))
    }

    /// Walks the four onboarding screens, changes the trigger, and checks the setup
    /// checklist survives into History, Settings and Help.
    func testOnboardingSetupChecklist() {
        app.launch()
        let primary = app.buttons["onboardingPrimary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5))
        snap("10-onboarding-welcome")
        primary.tap()

        // Trigger chooser: Action Button is preselected on the simulator; pick Back Tap.
        let backTap = app.buttons["trigger-backTap"]
        XCTAssertTrue(backTap.waitForExistence(timeout: 5))
        snap("11-onboarding-trigger")
        backTap.tap()
        XCTAssertTrue(backTap.isSelected)
        primary.tap()

        // Checklist: step 2 names the chosen trigger; mark it done by hand.
        XCTAssertTrue(app.staticTexts["Assign it to Back Tap"].waitForExistence(timeout: 5))
        snap("12-onboarding-setup")
        let markAssigned = app.buttons["markAssigned"]
        if !markAssigned.isHittable { app.swipeUp() }
        markAssigned.tap()
        XCTAssertTrue(app.staticTexts["1 of 3 done"].waitForExistence(timeout: 3))
        snap("13-onboarding-setup-marked")
        primary.tap()

        snap("14-onboarding-privacy")
        XCTAssertEqual(primary.label, "Get started")
        primary.tap()

        // History carries the unfinished setup as a card once there is a list to show it in.
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        let finish = app.buttons["emptyFinishSetup"]
        XCTAssertTrue(finish.waitForExistence(timeout: 5))
        snap("15-history-empty-finish-setup")
        finish.tap()
        XCTAssertTrue(app.navigationBars["Setup"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 of 3 done"].exists)
        snap("16-setup-screen")
        app.navigationBars.buttons.firstMatch.tap()

        app.tabBars.buttons["Settings"].tap()
        let setupRow = app.buttons["Trigger & Setup, 1 of 3"].firstMatch
        XCTAssertTrue(setupRow.waitForExistence(timeout: 5), "Settings should show setup progress")
        let help = app.buttons["Help & Setup"].firstMatch
        help.tap()
        XCTAssertTrue(app.navigationBars["Help & Setup"].waitForExistence(timeout: 5))
        snap("17-help")
        let actionButtonRow = app.buttons["help-trigger-actionButton"].firstMatch
        XCTAssertTrue(actionButtonRow.waitForExistence(timeout: 3))
        actionButtonRow.tap()
        XCTAssertTrue(app.buttons["Use Action Button"].waitForExistence(timeout: 3))
        snap("18-help-trigger-expanded")
    }
}
