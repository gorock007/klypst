import AppIntents
import Foundation
import KlypstCore
import UniformTypeIdentifiers

/// The one action for Shortcuts. Saves whatever was just copied, shows the recent clips,
/// and returns the chosen one. Followed by Shortcuts' own "Copy to Clipboard" this never
/// opens Klypst, because Shortcuts performs the pasteboard write.
///
/// Text and images both flow through here. Shortcuts coerces a copied image into a file
/// name when it lands in a string parameter, so the recipe also passes Get Images from
/// Input: whenever an image arrives, the string is an artifact and is ignored outright.
/// That check is deterministic, unlike `UIPasteboard`'s `has*` flags, which are not
/// dependable from an intent running in the background.
///
/// The result is an `IntentFile` rather than text, because a value that must sometimes
/// carry an image cannot be a `String`. Text clips come back as a plain-text file, which
/// Copy to Clipboard puts on the clipboard as text.
///
/// Keep the recipe linear. Hand-built If blocks broke the picker card on device
/// (11 Sep 2026); an empty variable wired into a file parameter is fine.
///
/// Recommended shortcut: Get Clipboard → Get Images from Input → Pick a Clip
/// (Save First: Clipboard, Save Image First: Images) → Copy to Clipboard.
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
            \.$saveImageFirst
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

    @Parameter(title: "Save Image First", description: "Optional. Pass Get Images from Input (run on the Clipboard variable) so copied images are saved too. Wins over Save First.", supportedContentTypes: [.image], inputConnectionBehavior: .never)
    var saveImageFirst: IntentFile?

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

    /// An image and a string can arrive together, because Shortcuts fills a string
    /// parameter with the image's file name. The image is always the real content.
    @MainActor
    private func saveWhatWasJustCopied(into repository: any ClipRepository, environment: AppEnvironment) async throws {
        if let saveImageFirst, let data = try? await saveImageFirst.data, !data.isEmpty {
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
