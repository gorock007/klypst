import Foundation
import Testing
@testable import KlypstCore

@Suite("PreferencesStore")
struct PreferencesTests {
    private func makeStore() -> PreferencesStore {
        PreferencesStore(suiteName: "KlypstTests-\(UUID().uuidString)")
    }

    @Test func pasteboardWritesAreLocalOnlyAndPermanentByDefault() {
        let store = makeStore()
        #expect(store.allowsUniversalClipboard == false)
        #expect(store.pasteboardExpiry == .never)
        let options = store.pasteboardWriteOptions
        #expect(options.isLocalOnly == true)
        #expect(options.expirationDate() == nil)
    }

    @Test func pasteboardSettingsRoundTripAndReset() {
        let store = makeStore()
        store.allowsUniversalClipboard = true
        store.pasteboardExpiry = .tenMinutes
        #expect(store.pasteboardWriteOptions.isLocalOnly == false)
        #expect(store.pasteboardWriteOptions.expiry == .tenMinutes)

        store.reset()
        #expect(store.allowsUniversalClipboard == false)
        #expect(store.pasteboardExpiry == .never)
    }

    @Test func expirationDateFollowsExpiry() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let options = PasteboardWriteOptions(isLocalOnly: true, expiry: .oneMinute)
        #expect(options.expirationDate(now: now) == now.addingTimeInterval(60))
        #expect(PasteboardWriteOptions(expiry: .never).expirationDate(now: now) == nil)
        #expect(PasteboardExpiry(rawValue: 3600) == .oneHour)
    }

    @Test func setupStartsUndecidedAndEmpty() {
        let store = makeStore()
        #expect(store.captureTrigger == .undecided)
        let progress = store.setupProgress
        #expect(progress.completedCount == 0)
        #expect(progress.isComplete == false)
        #expect(SetupProgress.stepCount == 3)
    }

    @Test func manualStepsCountAndTriggerRoundTrips() {
        let store = makeStore()
        store.captureTrigger = .backTap
        store.setupShortcutAdded = true
        #expect(store.setupProgress.trigger == .backTap)
        #expect(store.setupProgress.completedCount == 1)
        store.setupTriggerAssigned = true
        #expect(store.setupProgress.completedCount == 2)
        #expect(store.setupProgress.isComplete == false)
    }

    @Test func aRecordedRunCompletesEveryStep() {
        let store = makeStore()
        let when = Date(timeIntervalSince1970: 2_000_000)
        store.recordShortcutRun(at: when)
        store.recordShortcutRun(at: when.addingTimeInterval(5))
        #expect(store.shortcutRunCount == 2)
        #expect(store.lastShortcutRunAt == when.addingTimeInterval(5))
        let progress = store.setupProgress
        #expect(progress.isComplete)
        #expect(progress.completedCount == 3)
        #expect(progress.shortcutAdded && progress.triggerAssigned)

        store.hasDismissedSetupCard = true
        store.reset()
        #expect(store.shortcutRunCount == 0)
        #expect(store.captureTrigger == .undecided)
        #expect(store.hasDismissedSetupCard == false)
    }

    @Test func triggerChoicesExcludeUndecided() {
        #expect(!CaptureTrigger.choices.contains(.undecided))
        #expect(Set(CaptureTrigger.choices).count == CaptureTrigger.choices.count)
        #expect(CaptureTrigger(rawValue: "backTap")?.displayName == "Back Tap")
    }
}
