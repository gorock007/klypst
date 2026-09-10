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
                    .foregroundStyle(Color.brandInkSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
            } else {
                ForEach(clips) { clip in
                    Button(intent: CopyClipIntent(clip: clip)) {
                        ClipCardRow(clip: clip, trailing: clip.id == copiedID ? .copied : .copy)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(clip.accessibilityDescription)
                    .accessibilityHint("Copies this clip")
                }
            }

            Button(intent: OpenKlypstIntent()) {
                Label("Open Klypst", systemImage: "arrow.up.forward.app")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brandRow, in: Capsule())
                    .overlay { Capsule().strokeBorder(Color.brandRowBorder, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }
}
