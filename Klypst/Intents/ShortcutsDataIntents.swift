import AppIntents
import Foundation
import KlypstCore

/// Returns recent clips as entities so a shortcut can do
/// "Get Recent Clips → Choose from List → Get Clip Text → Copy to Clipboard".
/// That path never needs Klypst to write the pasteboard from the background,
/// because Shortcuts' own Copy to Clipboard action does the write.
struct GetRecentClipsIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Recent Clips"
    static let description = IntentDescription(
        "Returns your most recent clips, pinned ones first. Use with Choose from List.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$limit) recent clips")
    }

    @Parameter(title: "Limit", default: 10, inclusiveRange: (1, 50))
    var limit: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[ClipEntity]> {
        guard let repository = AppEnvironment.shared.repository else { throw KlypstIntentError.storeUnavailable }
        let pinned = try await repository.pinned(limit: limit)
        let recent = try await repository.recent(limit: limit)
        var seen = Set<UUID>()
        let clips = (pinned + recent)
            .filter { seen.insert($0.id).inserted }
            .prefix(limit)
            .map(ClipEntity.init(summary:))
        return .result(value: Array(clips))
    }
}

/// Returns a clip's text or link as plain text for use in other actions.
struct GetClipTextIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Clip Text"
    static let description = IntentDescription(
        "Returns the text or link of a clip. Image clips can’t be returned as text.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Get text of \(\.$clip)")
    }

    @Parameter(title: "Clip")
    var clip: ClipEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let repository = AppEnvironment.shared.repository else { throw KlypstIntentError.storeUnavailable }
        guard let content = try await repository.clip(id: clip.id) else { throw KlypstIntentError.clipNotFound }
        switch content.kind {
        case .text:
            guard let text = content.text else { throw KlypstIntentError.clipNotFound }
            try? await repository.markUsed(id: clip.id)
            return .result(value: text)
        case .url:
            guard let url = content.url else { throw KlypstIntentError.clipNotFound }
            try? await repository.markUsed(id: clip.id)
            return .result(value: url.absoluteString)
        case .image:
            throw KlypstIntentError.imageNotText
        }
    }
}

/// Returns an image clip as a file for use in other actions (Copy to Clipboard, Save to Photos…).
struct GetClipImageIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Clip Image"
    static let description = IntentDescription(
        "Returns an image clip as an image. Text and link clips can’t be returned as images.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Get image of \(\.$clip)")
    }

    @Parameter(title: "Clip")
    var clip: ClipEntity

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        guard let repository = AppEnvironment.shared.repository else { throw KlypstIntentError.storeUnavailable }
        guard let content = try await repository.clip(id: clip.id) else { throw KlypstIntentError.clipNotFound }
        let file = try ClipFile.image(from: content)
        try? await repository.markUsed(id: clip.id)
        return .result(value: file)
    }
}
