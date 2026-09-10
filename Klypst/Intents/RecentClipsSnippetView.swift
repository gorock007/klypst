import AppIntents
import KlypstCore
import SwiftUI

/// Interactive snippet body for Recent Clips. Each row runs `CopyClipIntent`;
/// the footer opens the app.
struct RecentClipsSnippetView: View {
    let clips: [ClipEntity]
    let copiedID: UUID?

    var body: some View {
        ClipCardPanel(subtitle: "Tap a clip to copy") {
            if clips.isEmpty {
                Text("Nothing here yet. Copy something and save it. It’ll be here when you need it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(clips.enumerated()), id: \.element.id) { index, clip in
                    Button(intent: CopyClipIntent(clip: clip)) {
                        ClipCardRow(clip: clip, isHighlighted: clip.id == copiedID, showsDivider: index < clips.count - 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(clip.accessibilityDescription)
                    .accessibilityHint("Copies this clip")
                }
            }

            Button(intent: OpenKlypstIntent()) {
                Label("Open Klypst", systemImage: "arrow.up.forward.app")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }
}
