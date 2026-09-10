import KlypstCore
import SwiftUI

struct ClipRow: View {
    let summary: ClipSummary

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 4) {
                Text(summary.preview)
                    .font(.body)
                    .lineLimit(summary.kind == .text ? 3 : 2)
                    .foregroundStyle(.primary)
                HStack(spacing: 6) {
                    Text(style.displayName)
                    Text("·")
                    Text(summary.lastUsedAt, style: .relative)
                    if summary.isPinned {
                        Text("·")
                        Image(systemName: "pin.fill")
                            .foregroundStyle(Color.accentColor)
                            .accessibilityLabel("Pinned")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var leading: some View {
        if summary.kind == .image, let url = summary.thumbnailURL {
            ThumbnailView(url: url)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Brand.Radius.tile, style: .continuous))
                .accessibilityHidden(true)
        } else {
            // A small "card" tile: the stack geometry, quietly.
            Image(systemName: style.systemImageName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(style == .code ? Color.brandCode : Color.brandInkSecondary)
                .frame(width: 36, height: 36)
                .background(style == .code ? Color.brandCodeTile : Color.brandSurfaceRaised, in: RoundedRectangle(cornerRadius: Brand.Radius.tile, style: .continuous))
                .accessibilityHidden(true)
        }
    }

    private var style: ClipDisplayStyle { ClipDisplayStyle(kind: summary.kind, preview: summary.preview) }

    private var accessibilityDescription: String {
        var parts = [style.displayName, summary.preview]
        if summary.isPinned { parts.append("Pinned") }
        parts.append("last used \(summary.lastUsedAt.formatted(.relative(presentation: .named)))")
        return parts.joined(separator: ", ")
    }
}

/// Loads a small thumbnail file off the main thread.
struct ThumbnailView: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            let loaded = await Task.detached(priority: .utility) { UIImage(contentsOfFile: url.path()) }.value
            guard !Task.isCancelled else { return }
            image = loaded
        }
    }
}
