import AppIntents
import Foundation
import KlypstCore

/// The image counterpart of `PickClipIntent`. Shows the user's recent image clips as a
/// system list and returns the chosen one as a file, which Shortcuts' own
/// "Copy to Clipboard" accepts. Like the text picker, this never opens Klypst.
///
/// Save First takes the Clipboard variable directly. It accepts text and URLs as well as
/// images for the reason documented on `PickClipIntent.copiedImage`: an image-only file
/// parameter makes Shortcuts render copied text into a picture. Anything that is not a
/// decodable image is ignored, so one trigger both saves a freshly copied image and
/// offers every saved image to paste.
///
/// Recommended shortcut: Get Clipboard → Pick an Image Clip (Save First: Clipboard)
/// → Copy to Clipboard.
struct PickImageClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Pick an Image Clip"
    static let description = IntentDescription(
        "Shows your recent image clips and returns the one you pick as an image. Follow with Copy to Clipboard.",
        categoryName: "Retrieve",
        searchKeywords: ["clipboard", "history", "paste", "image", "photo", "screenshot"]
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    static var parameterSummary: some ParameterSummary {
        Summary("Pick an image clip") {
            \.$saveFirst
            \.$clip
            \.$limit
        }
    }

    @Parameter(title: "Save First", description: "Optional. Pass the Clipboard variable to save a copied image before picking. Text is ignored.", supportedContentTypes: [.image, .plainText, .url], inputConnectionBehavior: .never)
    var saveFirst: IntentFile?

    // Never auto-connected: otherwise Shortcuts wires the previous result into it
    // and skips the picker.
    @Parameter(title: "Clip", description: "Leave empty to be asked each time the shortcut runs.", inputConnectionBehavior: .never)
    var clip: ClipEntity?

    @Parameter(title: "Show", description: "How many recent image clips to offer.", default: 8, inclusiveRange: (1, 25))
    var limit: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let environment = AppEnvironment.shared
        guard let repository = environment.repository else { throw KlypstIntentError.storeUnavailable }

        if let data = await ClipFile.imageData(in: saveFirst) {
            _ = try? await repository.save(.image(data, via: .intent))
            environment.markClipboardSeen()
            environment.state.bumpChangeToken()
        }

        let chosen: ClipEntity
        if let clip {
            chosen = clip
        } else {
            let pinned = try await repository.pinned(limit: limit)
            let recent = try await repository.recent(limit: limit * 3)
            var seen = Set<UUID>()
            let candidates = (pinned + recent)
                .filter { $0.kind == .image }
                .filter { seen.insert($0.id).inserted }
                .prefix(limit)
                .map(ClipEntity.init(summary:))
            guard !candidates.isEmpty else { throw KlypstIntentError.noImageClips }
            chosen = try await $clip.requestDisambiguation(among: Array(candidates), dialog: "Which image?")
        }

        guard let content = try await repository.clip(id: chosen.id) else { throw KlypstIntentError.clipNotFound }
        let file = try ClipFile.image(from: content)
        try? await repository.markUsed(id: chosen.id)
        environment.state.bumpChangeToken()
        KlypstLog.intents.info("Pick image intent returned an image clip.")
        return .result(value: file)
    }
}

/// Builds the `IntentFile` Shortcuts receives for a clip. Text and links come back as a
/// plain-text file so a single return type can carry either; Copy to Clipboard turns that
/// back into text. File names carry no clip content, only the format.
enum ClipFile {
    static func make(from content: ClipContent) throws -> IntentFile {
        switch content.kind {
        case .image:
            return try image(from: content)
        case .text:
            guard let value = content.text, !value.isEmpty else { throw KlypstIntentError.clipNotFound }
            return plainText(value)
        case .url:
            guard let url = content.url else { throw KlypstIntentError.clipNotFound }
            return plainText(url.absoluteString)
        }
    }

    static func image(from content: ClipContent) throws -> IntentFile {
        guard content.kind == .image else { throw KlypstIntentError.notAnImage }
        guard let payloadURL = content.payloadURL,
              let data = try? Data(contentsOf: payloadURL),
              let info = ImagePayloadStore.inspect(data)
        else { throw KlypstIntentError.clipNotFound }
        let fileExtension = info.contentType.preferredFilenameExtension ?? "png"
        return IntentFile(data: data, filename: "Klypst Clip.\(fileExtension)", type: info.contentType)
    }

    /// The bytes of `file` when it is a decodable image, otherwise nil. Judged from the
    /// bytes, not the declared type: Shortcuts hands over text files and, for links,
    /// nothing at all through the same parameter.
    static func imageData(in file: IntentFile?) async -> Data? {
        guard let file, let data = try? await file.data, !data.isEmpty,
              ImagePayloadStore.inspect(data) != nil else { return nil }
        return data
    }

    private static func plainText(_ value: String) -> IntentFile {
        IntentFile(data: Data(value.utf8), filename: "Klypst Clip.txt", type: .utf8PlainText)
    }
}
