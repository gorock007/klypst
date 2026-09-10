import AppIntents
import KlypstCore
import SwiftUI

/// Interactive snippet body. Each row runs `CopyClipIntent`; the footer opens the app.
struct RecentClipsSnippetView: View {
    let clips: [ClipEntity]
    let copiedID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Klypst", systemImage: "square.stack")
                    .font(.headline)
                Spacer()
                Text("Tap to copy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if clips.isEmpty {
                Text("No clips yet. Save your clipboard or share something to Klypst.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(clips) { clip in
                    Button(intent: CopyClipIntent(clip: clip)) {
                        SnippetRow(clip: clip, isCopied: clip.id == copiedID)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(clip.kind.displayName): \(clip.preview)")
                    .accessibilityHint("Copies this clip")
                }
            }

            Button(intent: OpenKlypstIntent()) {
                Label("Open Klypst", systemImage: "arrow.up.forward.app")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.top, 4)
        }
        .padding()
    }
}

private struct SnippetRow: View {
    let clip: ClipEntity
    let isCopied: Bool

    var body: some View {
        HStack(spacing: 10) {
            thumbnail
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.preview)
                    .font(.subheadline)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                HStack(spacing: 4) {
                    if clip.isPinned { Image(systemName: "pin.fill").font(.caption2) }
                    Text(clip.kind.displayName)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                .foregroundStyle(isCopied ? Color.accentColor : Color.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if clip.kind == .image, let url = clip.thumbnailURL, let image = UIImage(contentsOfFile: url.path()) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: clip.kind.systemImageName).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
