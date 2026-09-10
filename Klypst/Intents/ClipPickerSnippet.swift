import AppIntents
import KlypstCore
import SwiftUI

/// State for one Pick a Clip run: the offered clips and the current selection.
/// Lives in memory because the picking intent stays suspended in this process
/// while the card is on screen.
struct ClipPickerSession: Equatable {
    var clips: [ClipSummary]
    var selectedID: UUID?

    var selected: ClipSummary? {
        clips.first { $0.id == selectedID } ?? clips.first
    }
}

/// The branded picker card. Shown by `PickClipIntent` through
/// `requestConfirmation(snippetIntent:)`; its value is the clip returned on Continue.
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
            selectedID: selected.id
        )
        return .result(value: ClipEntity(summary: selected), view: view)
    }
}

/// Runs when a row on the picker card is tapped: moves the selection and redraws.
struct SelectPickerClipIntent: AppIntent {
    static let title: LocalizedStringResource = "Select Clip"
    static let isDiscoverable = false
    static let supportedModes: IntentModes = .background

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

/// Card body: each row selects; the system's Continue button returns the selection.
struct ClipPickerCardView: View {
    let clips: [ClipEntity]
    let selectedID: UUID

    var body: some View {
        ClipCardPanel(subtitle: "Pick a clip to copy") {
            ForEach(clips) { clip in
                let isSelected = clip.id == selectedID
                Button(intent: SelectPickerClipIntent(clipID: clip.id)) {
                    ClipCardRow(clip: clip, trailing: isSelected ? .selected : .unselected)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(clip.accessibilityDescription)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityHint(isSelected ? "Selected. Tap Continue to copy it." : "Selects this clip.")
            }
        }
    }
}
