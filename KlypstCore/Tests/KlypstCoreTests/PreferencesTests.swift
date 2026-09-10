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
}
