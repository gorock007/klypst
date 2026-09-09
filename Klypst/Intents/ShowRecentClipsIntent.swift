import AppIntents
import KlypstCore
import SwiftUI

/// Action Button / Siri / Spotlight entry point. Returns an interactive snippet on
/// iOS 26 surfaces that support it. Control Center controls can't show snippets,
/// so the Help screen steers users to the Action Button and Shortcuts.
struct ShowRecentClipsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Recent Clips"
    static let description = IntentDescription(
        "Shows your most recent and pinned clips. Tap one to copy it.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        guard AppEnvironment.shared.repository != nil else { throw KlypstIntentError.storeUnavailable }
        return .result(snippetIntent: RecentClipsSnippetIntent())
    }
}

/// The snippet itself. Re-run by the system whenever `reload()` is called.
struct RecentClipsSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Recent Clips"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let environment = AppEnvironment.shared
        guard let repository = environment.repository else { throw KlypstIntentError.storeUnavailable }

        // Small set: up to two pinned, then most recent, without duplicates.
        let pinned = try await repository.pinned(limit: 2)
        let recent = try await repository.recent(limit: KlypstConfiguration.snippetClipCount + 2)
        var seen = Set<UUID>()
        let clips = (pinned + recent)
            .filter { seen.insert($0.id).inserted }
            .prefix(KlypstConfiguration.snippetClipCount)
            .map(ClipEntity.init(summary:))

        let copiedID = environment.state.lastCopiedClipID
        return .result(view: RecentClipsSnippetView(clips: Array(clips), copiedID: copiedID))
    }
}

/// Opens the app from the snippet.
struct OpenKlypstIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Klypst"
    static let supportedModes: IntentModes = .foreground
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        .result()
    }
}
