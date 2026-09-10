import AppIntents
import Foundation
import KlypstCore

/// Saves content handed in by Shortcuts. This is what makes one-press capture
/// possible: a user shortcut does "Get Clipboard → Save to Klypst → Recent Clips",
/// and Shortcuts (a privileged system app) supplies the clipboard content, so
/// Klypst itself never reads the pasteboard in the background.
struct SaveClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Save to Klypst"
    static let description = IntentDescription(
        "Saves text, a link, or an image into Klypst. Pass the Clipboard variable to save whatever you last copied.",
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

    @Parameter(title: "Content", description: "Text or a link. Use the Clipboard variable to save what you last copied.")
    var content: String?

    @Parameter(title: "Image", description: "Optional image to save instead of text.", supportedContentTypes: [.image])
    var image: IntentFile?

    init() {}

    init(content: String) {
        self.content = content
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ClipEntity> & ProvidesDialog {
        guard let repository = AppEnvironment.shared.repository else { throw KlypstIntentError.storeUnavailable }

        let input: ClipInput
        if let image, let data = try? await image.data, !data.isEmpty {
            input = .image(data, via: .intent)
        } else if let content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            input = .text(content, via: .intent)
        } else {
            throw KlypstIntentError.nothingToSave
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
            return .result(value: ClipEntity(summary: summary), dialog: "Saved to Klypst.")
        case .duplicate(let summary):
            return .result(value: ClipEntity(summary: summary), dialog: "Already in Klypst — moved it to the top.")
        case .rejected(let reason):
            throw KlypstIntentError.saveRejected(reason.message)
        }
    }
}
