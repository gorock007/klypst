import AppIntents
import Foundation
import KlypstCore

/// Makes a stored clip the current clipboard. Runs in the background so it works
/// from the snippet, Shortcuts and Siri without opening the app.
struct CopyClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Copy Clip"
    static let description = IntentDescription(
        "Puts a saved clip on the clipboard so you can paste it.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Copy \(\.$clip)")
    }

    @Parameter(title: "Clip")
    var clip: ClipEntity

    init() {}

    init(clip: ClipEntity) {
        self.clip = clip
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            try await AppEnvironment.shared.copyClip(id: clip.id)
        } catch ClipRepositoryError.notFound {
            throw KlypstIntentError.clipNotFound
        } catch ClipRepositoryError.storeUnavailable {
            throw KlypstIntentError.storeUnavailable
        } catch {
            KlypstLog.intents.error("Copy intent failed: \(String(describing: type(of: error)), privacy: .public)")
            throw KlypstIntentError.copyFailed
        }
        RecentClipsSnippetIntent.reload()
        return .result(dialog: "Copied. Paste it anywhere.")
    }
}
