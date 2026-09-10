import AppIntents
import Foundation
import KlypstCore
import UIKit

/// Makes a stored clip the current clipboard.
///
/// iOS discards pasteboard writes from a backgrounded process without an error
/// (and `changeCount` still advances locally, so it can't be used to detect
/// this). When invoked from the snippet, Shortcuts or Siri while the app is not
/// active, the intent continues in the foreground, writes there, and shows a
/// toast telling the user to go back and paste.
struct CopyClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Copy Clip"
    static let description = IntentDescription(
        "Puts a saved clip on the clipboard so you can paste it.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
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
        let environment = AppEnvironment.shared

        // iOS silently discards UIPasteboard writes from a backgrounded process,
        // and changeCount still advances locally, so app state is the only
        // trustworthy signal. Bring the app forward first when needed.
        let neededForeground = UIApplication.shared.applicationState != .active
        if neededForeground {
            KlypstLog.intents.info("Copy intent invoked while backgrounded; continuing in foreground.")
            try await continueInForeground("Klypst needs to open briefly to copy this clip.", alwaysConfirm: false)
        }

        let tookEffect: Bool
        do {
            tookEffect = try await environment.copyClip(id: clip.id)
        } catch ClipRepositoryError.notFound {
            throw KlypstIntentError.clipNotFound
        } catch ClipRepositoryError.storeUnavailable {
            throw KlypstIntentError.storeUnavailable
        } catch {
            KlypstLog.intents.error("Copy intent failed: \(String(describing: type(of: error)), privacy: .public)")
            throw KlypstIntentError.copyFailed
        }
        guard tookEffect else { throw KlypstIntentError.copyFailed }

        if neededForeground {
            environment.state.showToast("Copied — go back to paste")
        }
        RecentClipsSnippetIntent.reload()
        return .result(dialog: "Copied. Paste it anywhere.")
    }
}
