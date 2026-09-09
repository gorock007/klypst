import AppIntents
import KlypstCore

/// Explicit, user-initiated clipboard capture.
///
/// Runs in the foreground: reading `UIPasteboard.general` is only reliable when
/// the app is frontmost, and it keeps the read visibly tied to the user's action.
struct SaveCurrentClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Save Current Clipboard"
    static let description = IntentDescription(
        "Saves whatever is on the clipboard right now into Klypst.",
        categoryName: "Capture"
    )
    static let supportedModes: IntentModes = .foreground
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let outcome = await AppEnvironment.shared.saveCurrentClipboard(via: .intent)
        AppEnvironment.shared.state.showToast(outcome.message, isSuccess: outcome.isSuccess)
        switch outcome {
        case .saved(let summary):
            KlypstLog.intents.info("Save intent stored a \(summary.kind.rawValue, privacy: .public) clip.")
            return .result(dialog: "Saved to Klypst.")
        case .duplicate:
            return .result(dialog: "That’s already in Klypst — moved it to the top.")
        case .nothingToSave:
            throw KlypstIntentError.nothingToSave
        case .failed(let message):
            throw KlypstIntentError.saveRejected(message)
        }
    }
}
