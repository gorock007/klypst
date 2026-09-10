import AppIntents
import Foundation
import KlypstCore

/// Saves content handed in by Shortcuts. This is what makes one-press capture
/// possible: a user shortcut does "Get Clipboard → Save to Klypst → Recent Clips",
/// and Shortcuts (a privileged system app) supplies the clipboard content, so
/// Klypst itself never reads the pasteboard in the background.
///
/// Silent by design: it is usually one step in a chain, so it shows no dialog
/// and treats an empty clipboard as a no-op rather than an error.
struct SaveClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Save to Klypst"
    static let description = IntentDescription(
        "Saves text, a link, or an image into Klypst. Pass the Clipboard variable to save whatever you last copied. Returns the saved clip.",
        categoryName: "Capture",
        searchKeywords: ["clipboard", "clip", "copy", "link"]
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$content) to Klypst") {
            \.$image
        }
    }

    // Required so Shortcuts auto-fills it with the previous action's output
    // (the Clipboard variable). An optional parameter is left blank.
    @Parameter(title: "Content", description: "Text or a link. Use the Clipboard variable to save what you last copied.", requestValueDialog: "What should Klypst save?", inputConnectionBehavior: .connectToPreviousIntentResult)
    var content: String

    @Parameter(title: "Image", description: "Optional image to save instead of text.", supportedContentTypes: [.image], inputConnectionBehavior: .never)
    var image: IntentFile?

    init() {}

    init(content: String) {
        self.content = content
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ClipEntity?> {
        guard let repository = AppEnvironment.shared.repository else { throw KlypstIntentError.storeUnavailable }

        let input: ClipInput
        if let image, let data = try? await image.data, !data.isEmpty {
            input = .image(data, via: .intent)
        } else if !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            input = .text(content, via: .intent)
        } else {
            KlypstLog.intents.info("Save intent received nothing to save.")
            return .result(value: nil)
        }

        let result: SaveResult
        do {
            result = try await repository.save(input)
        } catch {
            KlypstLog.intents.error("Save intent failed: \(String(describing: type(of: error)), privacy: .public)")
            throw KlypstIntentError.saveRejected("Klypst couldn’t save that.")
        }
        AppEnvironment.shared.state.bumpChangeToken()
        AppEnvironment.shared.markClipboardSeen()

        switch result {
        case .saved(let summary):
            KlypstLog.intents.info("Save intent stored a \(summary.kind.rawValue, privacy: .public) clip.")
            return .result(value: ClipEntity(summary: summary))
        case .duplicate(let summary):
            return .result(value: ClipEntity(summary: summary))
        case .rejected(let reason):
            throw KlypstIntentError.saveRejected(reason.message)
        }
    }
}
