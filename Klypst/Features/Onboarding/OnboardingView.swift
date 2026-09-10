import SwiftUI

/// Four short, behavioral screens (brand §13). Copy only claims what ships.
struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    @State private var mascotShown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [Page] = [
        Page(
            visual: .mascot,
            title: "Your clipboard remembers.",
            body: "Save the things you copy and bring them back when you need them."
        ),
        Page(
            visual: .glyph("magnifyingglass"),
            title: "Nothing useful gets buried.",
            body: "Find recent text, links and images in seconds."
        ),
        Page(
            visual: .glyph("button.horizontal.top.press"),
            title: "Keep it one press away.",
            body: "Set up the Action Button for the fastest path back to recent clips."
        ),
        Page(
            visual: .glyph("lock"),
            title: "Private by default.",
            body: "Your clipboard history stays on your iPhone. No account. No tracking."
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    pageView(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .padding(.bottom, 20)

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation(reduceMotion ? nil : Brand.Motion.settle) { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Get started" : "Continue")
            }
            .buttonStyle(.brandPrimary)
            .padding(.horizontal, 24)
            .accessibilityIdentifier("onboardingPrimary")

            Button("Skip") { onFinish() }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.brandInkSecondary)
                .padding(.top, 14)
                .padding(.bottom, 20)
                .opacity(isLastPage ? 0 : 1)
                .accessibilityHidden(isLastPage)
        }
        .brandCanvas()
        .onAppear {
            if reduceMotion {
                mascotShown = true
            } else {
                withAnimation(Brand.Motion.settle.delay(0.1)) { mascotShown = true }
            }
        }
    }

    // MARK: Pieces

    private func pageView(_ item: Page) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 24)
            HStack {
                Spacer()
                switch item.visual {
                case .mascot:
                    MascotView(height: 230)
                        .scaleEffect(mascotShown ? 1 : 0.9)
                        .opacity(mascotShown ? 1 : 0)
                case .glyph(let symbol):
                    CardStackGlyph(symbol: symbol, size: 128)
                }
                Spacer()
            }
            Spacer(minLength: 24)
            Text(item.title)
                .font(.largeTitle.bold())
                .kerning(-0.5)
                .foregroundStyle(Color.brandInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.body)
                .font(.title3)
                .foregroundStyle(Color.brandInkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Color.accentColor : Color.brandSeparator)
                    .frame(width: index == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : Brand.Motion.settle, value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
    }

    private struct Page {
        enum Visual {
            case mascot
            case glyph(String)
        }

        let visual: Visual
        let title: String
        let body: String
    }
}
