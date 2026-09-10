import KlypstCore
import SwiftUI

// Clip card content shared by the Pick a Clip picker and the Recent Clips snippet.
//
// Snippet views are archived and rendered by a system process, so only plain
// SwiftUI is used: semantic colors, SF Symbols, bundled images, gradients.
// `Color.accentColor` resolves to the host's tint (system blue) there, so the
// brand orange is an explicit value. iOS owns the container, its material, and
// any Cancel/Continue chrome; this file only draws the content inside it.

enum ClipCard {
    /// Klypst orange, #FF5A36. Explicit because the accent color is not ours in a snippet.
    static let orange = Color(red: 1.0, green: 0.353, blue: 0.212)
}

/// Compact header (real logo, title, subtitle) followed by a continuous list of rows.
struct ClipCardPanel<Rows: View>: View {
    let subtitle: LocalizedStringKey
    @ViewBuilder var rows: Rows

    @ScaledMetric(relativeTo: .title3) private var logoSize = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
                .padding(.bottom, 6)
            rows
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        // No background of our own: the system sheet clips content to its own
        // shape, so any tint we draw shows a hard rectangular edge at the corner.
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(.mascotSmall)
                .resizable()
                .scaledToFit()
                .frame(width: logoSize, height: logoSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Klypst")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// One clip: leading tile, one-line content, "Kind · time". The row is the action;
/// there are no trailing controls unless it is the selected/copied one.
struct ClipCardRow: View {
    let clip: ClipEntity
    var isHighlighted = false
    var showsDivider = true

    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 36

    private var style: ClipDisplayStyle { clip.displayStyle }
    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ClipKindTile(style: style, thumbnailURL: clip.thumbnailURL, isHighlighted: isHighlighted, size: tileSize)
                VStack(alignment: .leading, spacing: 2) {
                    Text(clip.preview)
                        .font(.subheadline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.primary)
                    HStack(spacing: 3) {
                        if clip.isPinned {
                            Image(systemName: "pin.fill")
                                .foregroundStyle(ClipCard.orange)
                        }
                        Text("\(style.displayName) · \(clip.lastUsedAt.formatted(.relative(presentation: .named)))")
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if isHighlighted {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(ClipCard.orange, in: Circle())
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, isHighlighted ? 8 : 0)
            .padding(.vertical, 9)
            .background {
                if isHighlighted {
                    shape.fill(ClipCard.orange.opacity(0.13))
                    shape.strokeBorder(ClipCard.orange.opacity(0.6), lineWidth: 1)
                }
            }
            .contentShape(Rectangle())

            if showsDivider {
                Divider()
                    .opacity(isHighlighted ? 0 : 0.6)
                    .padding(.leading, tileSize + 12)
            }
        }
    }
}

/// Leading square: the real thumbnail for images, otherwise the kind's symbol on a neutral tile.
struct ClipKindTile: View {
    let style: ClipDisplayStyle
    let thumbnailURL: URL?
    let isHighlighted: Bool
    var size: CGFloat = 36

    private let shape = RoundedRectangle(cornerRadius: 8, style: .continuous)

    var body: some View {
        Group {
            if style == .image, let thumbnailURL, let image = UIImage(contentsOfFile: thumbnailURL.path()) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: style.systemImageName)
                    .font(.system(size: size * 0.44, weight: .medium))
                    .foregroundStyle(isHighlighted ? Color.white : Color.primary.opacity(0.75))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(isHighlighted ? ClipCard.orange : Color(uiColor: .tertiarySystemFill))
            }
        }
        .frame(width: size, height: size)
        .clipShape(shape)
        .accessibilityHidden(true)
    }
}

extension ClipEntity {
    var displayStyle: ClipDisplayStyle { ClipDisplayStyle(kind: kind, preview: preview) }

    /// Spoken description for a row: "Link, https://…, pinned, last used now".
    var accessibilityDescription: String {
        var parts = [displayStyle.displayName, preview]
        if isPinned { parts.append("Pinned") }
        parts.append("last used \(lastUsedAt.formatted(.relative(presentation: .named)))")
        return parts.joined(separator: ", ")
    }
}
