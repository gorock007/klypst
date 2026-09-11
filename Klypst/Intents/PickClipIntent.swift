import AppIntents
import Foundation
import KlypstCore
import UIKit

/// The one-action picker for Shortcuts. Optionally saves the clipboard first,
/// shows the user's recent text/link clips, and returns the chosen clip's text.
/// Followed by Shortcuts' own "Copy to Clipboard" this never opens Klypst,
/// because Shortcuts performs the pasteboard write.
///
/// Two styles: the Klypst card (tap a clip, then the system Copy button) and
/// the plain system list (one tap). A snippet row can't return a value to the
/// shortcut on its own; only the confirmation button can, so the card needs
/// Copy. With nothing selected, Copy returns the newest clip, which is
/// the one just saved, so the copy is a no-op.
///
/// Images: Shortcuts can't receive an image from an action that returns text, so when
/// an image clip is picked Klypst continues in the foreground, writes the image to the
/// pasteboard itself (as `CopyClipIntent` does), and returns an empty string. The
/// recipe wraps Copy to Clipboard in "If … has any value" so that empty result never
/// overwrites the image.
///
/// Recommended shortcut (see `KlypstLinks.actionButtonShortcutFile`):
/// Get Clipboard → Get Images from Input → Pick a Clip (Save First: Clipboard, Save Image
/// First: Images) → If result has any value: Copy to Clipboard.
struct PickClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Pick a Clip"
    static let description = IntentDescription(
        "Shows your recent clips and returns the text of the one you pick. Pass the Clipboard variable to Save First to also save what you last copied. Follow with Copy to Clipboard.",
        categoryName: "Retrieve",
        searchKeywords: ["clipboard", "history", "paste", "choose"]
    )
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]
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
            \.$includeImages
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

    // Never auto-connected: Shortcuts would try to turn a text clipboard into an image.
    // The recipe wires it to "Get Images from Input" (empty for text, so this is nil),
    // and Save First to the Clipboard variable. When both arrive, the image wins.
    @Parameter(title: "Save Image First", description: "Optional. Pass Get Images from Input (run on the Clipboard variable) to save a copied image before picking. Takes priority over Save First.", supportedContentTypes: [.image], inputConnectionBehavior: .never)
    var saveImageFirst: IntentFile?

    @Parameter(title: "Include Images", description: "Offer image clips too. Picking an image copies it from Klypst directly and returns nothing, so put Copy to Clipboard inside an If … has any value.", default: true)
    var includeImages: Bool

    @Parameter(title: "Clip", description: "Leave empty to be asked each time the shortcut runs.", inputConnectionBehavior: .never)
    var clip: ClipEntity?

    @Parameter(title: "Show", description: "How many recent clips to offer.", default: 5, inclusiveRange: (1, 25))
    var limit: Int

    @Parameter(title: "Style", description: "Klypst Card shows your clips on the Klypst card: tap one, then Copy. Quick List is the plain system list, where one tap picks.", default: .card)
    var style: Style

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let environment = AppEnvironment.shared
        guard let repository = environment.repository else { throw KlypstIntentError.storeUnavailable }

        if let saveImageFirst, let data = try? await saveImageFirst.data, !data.isEmpty {
            _ = try? await repository.save(.image(data, via: .intent))
            environment.markClipboardSeen()
            environment.state.bumpChangeToken()
        } else if let saveFirst, let text = ShortcutsCoercion.textToSave(saveFirst) {
            _ = try? await repository.save(.text(text, via: .intent))
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
            let candidates = Array((pinned + recent)
                .filter { includeImages || $0.kind != .image }
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
        let text: String
        switch content.kind {
        case .text: text = content.text ?? ""
        case .url: text = content.url?.absoluteString ?? ""
        case .image:
            // iOS discards pasteboard writes from a backgrounded process, so bring
            // the app forward first, write the image here, and hand Shortcuts nothing.
            if UIApplication.shared.applicationState != .active {
                KlypstLog.intents.info("Pick intent chose an image while backgrounded; continuing in foreground.")
                try await continueInForeground("Klypst needs to open briefly to copy this image.", alwaysConfirm: false)
            }
            let tookEffect: Bool
            do {
                tookEffect = try await environment.copyClip(id: chosen.id)
            } catch {
                KlypstLog.intents.error("Pick intent image copy failed: \(String(describing: type(of: error)), privacy: .public)")
                throw KlypstIntentError.copyFailed
            }
            guard tookEffect else { throw KlypstIntentError.copyFailed }
            environment.state.showToast("Copied — go back to paste")
            KlypstLog.intents.info("Pick intent copied an image clip in-process.")
            return .result(value: "")
        }
        guard !text.isEmpty else { throw KlypstIntentError.clipNotFound }
        try? await repository.markUsed(id: chosen.id)
        environment.state.bumpChangeToken()
        KlypstLog.intents.info("Pick intent returned a \(content.kind.rawValue, privacy: .public) clip.")
        return .result(value: text)
    }
}
