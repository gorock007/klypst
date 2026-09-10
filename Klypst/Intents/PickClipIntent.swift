import AppIntents
import Foundation
import KlypstCore

/// The one-action picker for Shortcuts. Optionally saves the clipboard first,
/// shows the user's recent text/link clips as a system list, and returns the
/// chosen clip's text. Followed by Shortcuts' own "Copy to Clipboard" this
/// never opens Klypst, because Shortcuts performs the pasteboard write.
///
/// Recommended shortcut: Get Clipboard → Pick a Clip (Save First: Clipboard) → Copy to Clipboard.
struct PickClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Pick a Clip"
    static let description = IntentDescription(
        "Shows your recent clips and returns the text of the one you pick. Pass the Clipboard variable to Save First to also save what you last copied. Follow with Copy to Clipboard.",
        categoryName: "Retrieve",
        searchKeywords: ["clipboard", "history", "paste", "choose"]
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Pick a clip") {
            \.$saveFirst
            \.$clip
            \.$limit
        }
    }

    // Connected to the previous action (Get Clipboard) automatically; the Clip
    // parameter is never auto-connected, otherwise Shortcuts wires the clipboard
    // text into it, resolves it to an entity, and the picker is skipped.
    @Parameter(title: "Save First", description: "Optional. Pass the Clipboard variable to save what you last copied before picking.", inputConnectionBehavior: .connectToPreviousIntentResult)
    var saveFirst: String?

    @Parameter(title: "Clip", description: "Leave empty to be asked each time the shortcut runs.", inputConnectionBehavior: .never)
    var clip: ClipEntity?

    @Parameter(title: "Show", description: "How many recent clips to offer.", default: 8, inclusiveRange: (1, 25))
    var limit: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let environment = AppEnvironment.shared
        guard let repository = environment.repository else { throw KlypstIntentError.storeUnavailable }

        if let saveFirst, !saveFirst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            _ = try? await repository.save(.text(saveFirst, via: .intent))
            environment.markClipboardSeen()
            environment.state.bumpChangeToken()
        }

        let chosen: ClipEntity
        if let clip {
            chosen = clip
        } else {
            let pinned = try await repository.pinned(limit: limit)
            let recent = try await repository.recent(limit: limit + 5)
            var seen = Set<UUID>()
            let candidates = (pinned + recent)
                .filter { $0.kind != .image }
                .filter { seen.insert($0.id).inserted }
                .prefix(limit)
                .map(ClipEntity.init(summary:))
            guard !candidates.isEmpty else { throw KlypstIntentError.noClips }
            chosen = try await $clip.requestDisambiguation(among: Array(candidates), dialog: "Which clip?")
        }

        guard let content = try await repository.clip(id: chosen.id) else { throw KlypstIntentError.clipNotFound }
        let text: String
        switch content.kind {
        case .text: text = content.text ?? ""
        case .url: text = content.url?.absoluteString ?? ""
        case .image: throw KlypstIntentError.imageNotText
        }
        guard !text.isEmpty else { throw KlypstIntentError.clipNotFound }
        try? await repository.markUsed(id: chosen.id)
        environment.state.bumpChangeToken()
        KlypstLog.intents.info("Pick intent returned a \(content.kind.rawValue, privacy: .public) clip.")
        return .result(value: text)
    }
}
