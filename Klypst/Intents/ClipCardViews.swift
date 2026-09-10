import KlypstCore
import SwiftUI

// Branded clip card shared by the Pick a Clip picker and the Recent Clips snippet.
// Snippet views are archived and rendered by the system, so everything here is
// plain SwiftUI: asset-catalog colors, gradients, a small mascot, SF Symbols.

/// Panel with the mascot header and a stack of clip rows.
struct ClipCardPanel<Rows: View>: View {
    let subtitle: LocalizedStringKey
    @ViewBuilder var rows: Rows

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            VStack(spacing: 8) { rows }
        }
        .padding(16)
        .background { ClipCardBackground() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(.mascotSmall)
                .resizable()
                .scaledToFit()
                .frame(width: 54, height: 54)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Klypst")
                    .font(.title2.bold())
                    .foregroundStyle(Color.brandInk)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandInkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Near-black (or white) panel with a restrained orange glow in the top trailing corner.
struct ClipCardBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.brandPanel
            RadialGradient(
                colors: [Color.accentColor.opacity(colorScheme == .dark ? 0.5 : 0.22), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 320
            )
        }
    }
}

/// One clip in the stack: kind tile, preview, "Kind • time", trailing state.
struct ClipCardRow: View {
    enum Trailing {
        /// Tapping copies (Recent Clips snippet).
        case copy
        /// Just copied.
        case copied
        /// Picker row that isn't selected.
        case unselected
        /// Picker row that will be returned on Continue.
        case selected
    }

    let clip: ClipEntity
    let trailing: Trailing

    @Environment(\.colorScheme) private var colorScheme

    private var isHighlighted: Bool { trailing == .selected || trailing == .copied }
    private var style: ClipDisplayStyle { clip.displayStyle }
    private let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

    var body: some View {
        HStack(spacing: 14) {
            ClipKindTile(style: style, thumbnailURL: clip.thumbnailURL, isHighlighted: isHighlighted)
            VStack(alignment: .leading, spacing: 3) {
                Text(clip.preview)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(Color.brandInk)
                HStack(spacing: 5) {
                    if clip.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                    Text("\(style.displayName) • \(clip.lastUsedAt.formatted(.relative(presentation: .named)))")
                        .lineLimit(1)
                }
                .font(.subheadline)
                .foregroundStyle(Color.brandInkSecondary)
            }
            Spacer(minLength: 8)
            trailingView
        }
        .padding(10)
        .frame(minHeight: 70)
        .background(fill, in: shape)
        .overlay {
            shape.strokeBorder(isHighlighted ? Color.accentColor.opacity(0.85) : Color.brandRowBorder, lineWidth: 1)
        }
        .contentShape(shape)
    }

    private var fill: AnyShapeStyle {
        guard isHighlighted else { return AnyShapeStyle(Color.brandRow) }
        let strength = colorScheme == .dark ? 1.0 : 0.5
        return AnyShapeStyle(LinearGradient(
            colors: [Color.accentColor.opacity(0.42 * strength), Color.brandOrangeDeep.opacity(0.16 * strength)],
            startPoint: .leading,
            endPoint: .trailing
        ))
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailing {
        case .copy:
            Image(systemName: "square.on.square")
                .font(.title3)
                .foregroundStyle(Color.brandInkSecondary)
                .frame(width: 32, height: 32)
        case .unselected:
            Circle()
                .strokeBorder(Color.brandInkSecondary.opacity(0.55), lineWidth: 1.5)
                .frame(width: 28, height: 28)
                .frame(width: 32, height: 32)
        case .selected, .copied:
            Image(systemName: "checkmark")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color.accentColor, in: Circle())
        }
    }
}

/// Square tile at the start of a row: a thumbnail, or the kind's symbol.
struct ClipKindTile: View {
    let style: ClipDisplayStyle
    let thumbnailURL: URL?
    let isHighlighted: Bool

    private let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

    var body: some View {
        Group {
            if style == .image, let thumbnailURL, let image = UIImage(contentsOfFile: thumbnailURL.path()) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: style.systemImageName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(symbolColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(tileFill)
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(shape)
        .accessibilityHidden(true)
    }

    private var symbolColor: Color {
        if isHighlighted { return .white }
        return style == .code ? .brandCode : .brandInk.opacity(0.85)
    }

    private var tileFill: AnyShapeStyle {
        if isHighlighted {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.brandOrangeSoft, Color.accentColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
        return AnyShapeStyle(style == .code ? Color.brandCodeTile : Color.brandTile)
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
