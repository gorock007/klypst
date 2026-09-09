import Foundation
import Observation

/// Observable UI state shared across the app and in-process intents.
@MainActor
@Observable
final class AppState {
    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let isSuccess: Bool
    }

    enum PendingAction: Equatable {
        case saveClipboard
        case showClip(UUID)
    }

    /// Incremented whenever the store changes; lists reload on it.
    private(set) var changeToken = 0
    var toast: Toast?
    var pendingAction: PendingAction?
    var lastCopiedClipID: UUID?

    func bumpChangeToken() {
        changeToken &+= 1
    }

    func showToast(_ message: String, isSuccess: Bool = true) {
        toast = Toast(message: message, isSuccess: isSuccess)
    }
}
