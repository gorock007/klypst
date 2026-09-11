import AppIntents
import Foundation
import KlypstCore
import UniformTypeIdentifiers

/// The one action for Shortcuts. Saves whatever was just copied, shows the recent clips,
/// and returns the chosen one. Followed by Shortcuts' own "Copy to Clipboard" this never
/// opens Klypst, because Shortcuts performs the pasteboard write.
///
/// The recipe passes the Clipboard variable twice: into Save First (a string) and into
/// Copied Image (a file). Shortcuts fills the string with an image's file name, and fills
/// the file parameter with whatever the clipboard holds: text becomes a tiny text file,
/// an image stays an image, a link becomes nothing. Only a real image in the file
/// parameter is used; then the string is an artifact and is ignored outright.
///
/// The file parameter accepts images, plain text and URLs on purpose. Measured with
/// Shortcuts on macOS 26 (11 Sep 2026): an image-only file parameter makes Shortcuts
/// *render copied text into a PNG* (Get Images from Input does the same), and a
/// parameter without `.url` makes it *download* a copied link. Accepting all three is
/// the only shape that never renders, never downloads and never blocks the action.
/// `UIPasteboard`'s `has*` flags are no alternative: not dependable in the background.
///
/// The result is an `IntentFile` rather than text, because a value that must sometimes
/// carry an image cannot be a `String`. Text clips come back as a plain-text file, which
/// Copy to Clipboard puts on the clipboard as text.
///
/// Recommended shortcut: Get Clipboard → Pick a Clip (Save First: Clipboard,
/// Copied Image: Clipboard) → Copy to Clipboard. Keep it linear; no Get Images from Input.
struct PickClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Pick a Clip"
    static let description = IntentDescription(
        "Saves what you just copied, shows your recent clips, and returns the one you pick. Follow with Copy to Clipboard.",
        categoryName: "Retrieve",
        searchKeywords: ["clipboard", "history", "paste", "choose", "image"]
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    /// Labels for the system confirmation buttons under the card. The button
    /// colors and layout are the host's; only the words are ours.
    static let copyAction: ConfirmationActionName = .custom(
        acceptLabel: "Copy",
        acceptAlternatives: ["copy it", "copy that", "yes"],
        denyLabel: "Cancel",
        denyAlternatives: ["no", "never mind"]
    )

    static var parameterSummary: some ParameterSummary {
        Summary("Pick a clip") {
            \.$saveFirst
            \.$copiedImage
            \.$clip
            \.$limit
            \.$style
        }
    }

    enum Style: String, AppEnum {
        case card
        case list

        static let typeDisplayRepresentation: TypeDisplayRepresentation = "Picker Style"
        static let caseDisplayRepresentations: [Style: DisplayRepresentation] = [
            .card: DisplayRepresentation(title: "Klypst Card", subtitle: "Tap a clip, then Copy"),
            .list: DisplayRepresentation(title: "Quick List", subtitle: "Plain system list, one tap"),
        ]
    }

    // Connected to the previous action (Get Clipboard) automatically; the Clip
    // parameter is never auto-connected, otherwise Shortcuts wires the clipboard
    // text into it, resolves it to an entity, and the picker is skipped.
    @Parameter(title: "Save First", description: "Optional. Pass the Clipboard variable to save what you last copied before picking.", inputConnectionBehavior: .connectToPreviousIntentResult)
    var saveFirst: String?

    // Accepts text and URLs as well as images so Shortcuts never renders text into a
    // picture or downloads a link to satisfy the parameter; see the type comment.
    @Parameter(title: "Copied Image", description: "Optional. Pass the Clipboard variable here as well, so a copied image is saved too. Text and links are handled by Save First.", supportedContentTypes: [.image, .plainText, .url], inputConnectionBehavior: .never)
    var copiedImage: IntentFile?

    @Parameter(title: "Clip", description: "Leave empty to be asked each time the shortcut runs.", inputConnectionBehavior: .never)
    var clip: ClipEntity?

    @Parameter(title: "Show", description: "How many recent clips to offer.", default: 5, inclusiveRange: (1, 25))
    var limit: Int

    @Parameter(title: "Style", description: "Klypst Card shows your clips on the Klypst card: tap one, then Copy. Quick List is the plain system list, where one tap picks.", default: .card)
    var style: Style

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let environment = AppEnvironment.shared
        guard let repository = environment.repository else { throw KlypstIntentError.storeUnavailable }

        try await saveWhatWasJustCopied(into: repository, environment: environment)

        let chosen: ClipEntity
        if let clip {
            chosen = clip
        } else {
            let pinned = try await repository.pinned(limit: limit)
            let recent = try await repository.recent(limit: limit + 5)
            var seen = Set<UUID>()
            let candidates = Array((pinned + recent)
                .filter { seen.insert($0.id).inserted }
                .prefix(limit))
            guard !candidates.isEmpty else { throw KlypstIntentError.noClips }

            switch style {
            case .card:
                environment.state.pickerSession = ClipPickerSession(clips: candidates, selectedID: nil)
                defer { environment.state.pickerSession = nil }
                chosen = try await requestConfirmation(actionName: Self.copyAction, snippetIntent: ClipPickerSnippetIntent())
            case .list:
                chosen = try await $clip.requestDisambiguation(
                    among: candidates.map(ClipEntity.init(summary:)),
                    dialog: "Pick a clip to copy"
                )
            }
        }

        guard let content = try await repository.clip(id: chosen.id) else { throw KlypstIntentError.clipNotFound }
        let file = try ClipFile.make(from: content)
        try? await repository.markUsed(id: chosen.id)
        environment.state.bumpChangeToken()
        KlypstLog.intents.info("Pick intent returned a \(content.kind.rawValue, privacy: .public) clip.")
        return .result(value: file)
    }

    /// An image and a string arrive together, because Shortcuts fills a string parameter
    /// with the image's file name. A decodable image is always the real content; a text
    /// file in Copied Image is just the clipboard text again and is left to Save First.
    @MainActor
    private func saveWhatWasJustCopied(into repository: any ClipRepository, environment: AppEnvironment) async throws {
        if let data = await ClipFile.imageData(in: copiedImage) {
            _ = try? await repository.save(.image(data, via: .intent))
            KlypstLog.intents.info("Pick intent saved a copied image; ignored any text alongside it.")
        } else if let saveFirst, let text = ShortcutsCoercion.textToSave(saveFirst) {
            _ = try? await repository.save(.text(text, via: .intent))
        } else {
            return
        }
        environment.markClipboardSeen()
        environment.state.bumpChangeToken()
    }
}
