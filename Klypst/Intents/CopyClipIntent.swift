import AppIntents
import Foundation
import KlypstCore
import UIKit

/// Makes a stored clip the current clipboard.
///
/// Tries to write from the background first (snippet, Shortcuts, Siri). iOS can
/// discard pasteboard writes from a backgrounded process, so the write is
/// verified via `changeCount`; if it did not take effect the intent continues
/// in the foreground, writes again, and shows a toast telling the user to go
/// back and paste.
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
        let wroteInBackground: Bool
        do {
            wroteInBackground = try await environment.copyClip(id: clip.id)
        } catch ClipRepositoryError.notFound {
            throw KlypstIntentError.clipNotFound
        } catch ClipRepositoryError.storeUnavailable {
            throw KlypstIntentError.storeUnavailable
        } catch {
            KlypstLog.intents.error("Copy intent failed: \(String(describing: type(of: error)), privacy: .public)")
            throw KlypstIntentError.copyFailed
        }

        if !wroteInBackground {
            KlypstLog.intents.info("Background pasteboard write was discarded; continuing in foreground.")
            try await continueInForeground("Klypst needs to open briefly to copy this clip.", alwaysConfirm: false)
            let wroteInForeground = try await environment.copyClip(id: clip.id)
            guard wroteInForeground else { throw KlypstIntentError.copyFailed }
            environment.state.showToast("Copied — go back to paste")
        }

        RecentClipsSnippetIntent.reload()
        return .result(dialog: "Copied. Paste it anywhere.")
    }
}
