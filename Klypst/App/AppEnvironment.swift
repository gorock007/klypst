import Foundation
import KlypstCore
import SwiftUI

/// Process-wide services. Built once; also used by App Intents running in-process.
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let storeResult: Result<KlypstStore, any Error>
    let clipboard = GeneralPasteboardClipboard()
    let state = AppState()

    private init() {
        storeResult = Result { try KlypstStore.shared() }
        if case .failure(let error) = storeResult {
            KlypstLog.app.fault("Shared store unavailable: \(String(describing: type(of: error)), privacy: .public)")
        }
        #if DEBUG
        // UI tests launch with `--reset-state` to start from a clean install.
        if CommandLine.arguments.contains("--reset-state"), let store {
            store.preferences.reset()
            Task { try? await store.repository.deleteAll() }
        }
        #endif
    }

    var store: KlypstStore? {
        try? storeResult.get()
    }

    var repository: (any ClipRepository)? { store?.repository }
    var preferences: PreferencesStore { store?.preferences ?? PreferencesStore() }

    func runRetention(force: Bool = false) async {
        guard let store else { return }
        let purged = await store.retention.runIfNeeded(force: force)
        if purged > 0 { state.bumpChangeToken() }
    }

    // MARK: User actions shared by views and intents

    /// Reads the pasteboard (user-initiated) and stores the result.
    func saveCurrentClipboard(via method: CaptureMethod = .manualSave) async -> SaveOutcome {
        guard let repository else { return .failed("The clip store isn’t available.") }
        do {
            guard var input = try await clipboard.readUserInitiatedContent() else {
                return .nothingToSave
            }
            input = ClipInput(payload: input.payload, captureMethod: method)
            let result = try await repository.save(input)
            state.bumpChangeToken()
            switch result {
            case .saved(let summary): return .saved(summary)
            case .duplicate(let summary): return .duplicate(summary)
            case .rejected(let reason): return .failed(reason.message)
            }
        } catch {
            KlypstLog.app.error("Save current clipboard failed: \(String(describing: type(of: error)), privacy: .public)")
            return .failed("Couldn’t save the clipboard.")
        }
    }

    /// Writes a stored clip to the pasteboard and refreshes its recency.
    func copyClip(id: UUID) async throws {
        guard let repository else { throw ClipRepositoryError.storeUnavailable }
        guard let content = try await repository.clip(id: id) else { throw ClipRepositoryError.notFound }
        try clipboard.write(content)
        try await repository.markUsed(id: id)
        state.lastCopiedClipID = id
        state.bumpChangeToken()
    }

    func setPinned(id: UUID, _ pinned: Bool) async throws {
        try await repository?.setPinned(id: id, pinned)
        state.bumpChangeToken()
    }

    func delete(id: UUID) async throws {
        try await repository?.delete(id: id)
        state.bumpChangeToken()
    }

    func deleteAll() async throws {
        try await repository?.deleteAll()
        state.bumpChangeToken()
    }
}

enum SaveOutcome: Sendable {
    case saved(ClipSummary)
    case duplicate(ClipSummary)
    case nothingToSave
    case failed(String)

    var message: String {
        switch self {
        case .saved: "Saved to Klypst"
        case .duplicate: "Already saved — moved to top"
        case .nothingToSave: "Nothing on the clipboard to save"
        case .failed(let message): message
        }
    }

    var isSuccess: Bool {
        switch self {
        case .saved, .duplicate: true
        case .nothingToSave, .failed: false
        }
    }
}
