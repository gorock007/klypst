import SwiftUI

/// Design tokens from `docs/brand.md`.
///
/// Colors live in the asset catalog so they adapt to dark mode without inverting:
/// `Color.brandBackground` (white / near-black), `.brandGroupedBackground`, `.brandSurface` (white / charcoal),
/// `.brandSurfaceRaised`, `.brandInk`, `.brandInkSecondary`, `.brandSeparator`,
/// `.brandOrangeDeep`, `.brandOrangeSoft`, and the app accent (coral orange).
///
/// Orange identifies the brand but must not cover the UI: use it for the mascot,
/// selection, copy success, active filters and primary CTAs. Everything else stays native.
enum Brand {
    static let tagline = "Your clipboard remembers."

    enum Radius {
        /// Editorial panels and the "front card" surfaces.
        static let card: CGFloat = 16
        /// Buttons and inline controls.
        static let control: CGFloat = 14
        /// Small leading tiles in rows.
        static let tile: CGFloat = 9
    }

    enum Motion {
        /// Quick, tactile, slightly springy: a card lifting or snapping.
        static let snap = Animation.spring(duration: 0.3, bounce: 0.3)
        /// A card settling into place.
        static let settle = Animation.spring(duration: 0.45, bounce: 0.12)
    }
}

// MARK: - Mascot

/// The stack-of-cards character. Reserved for brand moments (onboarding, empty
/// states, About). Never place it on clip rows.
struct MascotView: View {
    var height: CGFloat = 200

    var body: some View {
        Image(.mascot)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityHidden(true)
    }
}

/// Three softly layered cards with a symbol on the front card: the stack metaphor
/// without reinterpreting the mascot's face.
struct CardStackGlyph: View {
    let symbol: String
    var size: CGFloat = 120

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
        ZStack {
            shape
                .fill(Color.brandOrangeSoft.opacity(0.45))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-8))
                .offset(x: -size * 0.22, y: size * 0.04)
            shape
                .fill(Color.brandOrangeSoft)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-4))
                .offset(x: -size * 0.11, y: size * 0.02)
            shape
                .fill(Color.accentColor)
                .frame(width: size, height: size)
                .shadow(color: .black.opacity(0.12), radius: size * 0.12, x: 0, y: size * 0.06)
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: size * 0.4, weight: .semibold))
                        .foregroundStyle(.white)
                }
        }
        .frame(width: size * 1.3, height: size * 1.1)
        .accessibilityHidden(true)
    }
}

// MARK: - Controls

/// Primary brand CTA: orange card, warm-white bold label, soft corners.
struct BrandPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                configuration.isPressed ? Color.brandOrangeDeep : Color.accentColor,
                in: RoundedRectangle(cornerRadius: Brand.Radius.control, style: .continuous)
            )
            .opacity(isEnabled ? 1 : 0.5)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Brand.Motion.snap, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == BrandPrimaryButtonStyle {
    static var brandPrimary: BrandPrimaryButtonStyle { BrandPrimaryButtonStyle() }
}

// MARK: - Canvases

extension View {
    /// Brand canvas behind a screen: cream in light mode, near-black in dark mode.
    func brandCanvas() -> some View {
        background(Color.brandBackground.ignoresSafeArea())
    }

    /// For plain lists: replaces the system scroll background with the brand canvas.
    func brandListCanvas() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.brandBackground.ignoresSafeArea())
    }

    /// For grouped lists and forms: white rows on the grouped canvas (near-black in dark mode).
    func brandGroupedCanvas() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.brandGroupedBackground.ignoresSafeArea())
    }
}
