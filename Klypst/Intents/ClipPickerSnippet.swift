import AppIntents
import KlypstCore
import SwiftUI

/// State for one Pick a Clip run: the offered clips and the current selection.
/// Lives in memory because the picking intent stays suspended in this process
/// while the card is on screen.
struct ClipPickerSession: Equatable {
    var clips: [ClipSummary]
    /// Nil until the user taps a row. Copy with no selection returns the
    /// most recent clip, which is what was just saved, so it is a no-op copy.
    var selectedID: UUID?

    var selected: ClipSummary? {
        clips.first { $0.id == selectedID } ?? clips.first
    }
}

/// The card shown by `PickClipIntent` through `requestConfirmation(snippetIntent:)`.
/// Its value is the clip returned when the user taps the system Copy button.
struct ClipPickerSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Clip Picker"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<ClipEntity> & ShowsSnippetView {
        guard let session = AppEnvironment.shared.state.pickerSession,
              let selected = session.selected else {
            throw KlypstIntentError.noClips
        }
        let view = ClipPickerCardView(
            clips: session.clips.map(ClipEntity.init(summary:)),
            selectedID: session.selectedID
        )
        return .result(value: ClipEntity(summary: selected), view: view)
    }
}

/// Runs when a row on the picker card is tapped: moves the selection and redraws.
struct SelectPickerClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Select Clip"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Clip ID")
    var clipID: String

    init() {}

    init(clipID: UUID) {
        self.clipID = clipID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        if let id = UUID(uuidString: clipID) {
            AppEnvironment.shared.state.pickerSession?.selectedID = id
        }
        ClipPickerSnippetIntent.reload()
        return .result()
    }
}

/// Card body: tapping a row selects it; the system's Copy button returns it.
struct ClipPickerCardView: View {
    let clips: [ClipEntity]
    let selectedID: UUID?

    var body: some View {
        ClipCardPanel(subtitle: "Pick a clip to copy") {
            ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                let isSelected = clip.id == selectedID
                Button(intent: SelectPickerClipIntent(clipID: clip.id)) {
                    ClipCardRow(clip: clip, isHighlighted: isSelected, showsDivider: index < clips.count - 1)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clip.accessibilityDescription)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint(isSelected ? "Selected. Tap Copy to copy it." : "Selects this clip.")
            }
        }
    }
}
