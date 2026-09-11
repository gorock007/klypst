import KlypstCore
import SwiftUI

/// Four screens, each with one job (brand §13): the promise, the trigger choice, the
/// setup checklist, the privacy promise. Nothing blocks: Skip and Continue always work,
/// and unfinished setup follows the person into History as a card.
struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    @State private var mascotShown = false
    @State private var trigger = OnboardingView.initialTrigger
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static var initialTrigger: CaptureTrigger {
        let saved = AppEnvironment.shared.preferences.captureTrigger
        return saved == .undecided ? TriggerGuide.recommended : saved
    }

    private enum Step: Int, CaseIterable {
        case welcome, trigger, setup, privacy
    }

    private var step: Step { Step(rawValue: page) ?? .welcome }
    private var isLastPage: Bool { page == Step.allCases.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Step.allCases, id: \.rawValue) { item in
                    pageView(item)
                        .tag(item.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageIndicator
                .padding(.bottom, 20)

            Button {
                advance()
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
        .onChange(of: trigger) { _, newValue in
            AppEnvironment.shared.preferences.captureTrigger = newValue
            AppEnvironment.shared.setupDidChange()
        }
    }

    private func advance() {
        if step == .trigger, AppEnvironment.shared.preferences.captureTrigger == .undecided {
            // Leaving the chooser with the preselected trigger counts as choosing it.
            AppEnvironment.shared.preferences.captureTrigger = trigger
        }
        if isLastPage {
            onFinish()
        } else {
            withAnimation(reduceMotion ? nil : Brand.Motion.settle) { page += 1 }
        }
    }

    // MARK: Pages

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibilitySize }

    @ViewBuilder
    private func pageView(_ step: Step) -> some View {
        switch step {
        case .welcome:
            heroPage(
                visual: .mascot,
                title: "Your clipboard remembers.",
                body: "Copy anything. Press once to save it, press again to bring it back. Text, links and images."
            )
        case .trigger:
            formPage(
                title: "How will you call Klypst?",
                body: "One shortcut does everything; this is only the button that runs it. Change it any time."
            ) {
                TriggerPickerView(selection: $trigger)
                Text("More options, like the Lock Screen and Siri, are in Setup.")
                    .font(.footnote)
                    .foregroundStyle(Color.brandInkSecondary)
                    .padding(.top, 4)
            }
        case .setup:
            formPage(
                title: "Two minutes, once.",
                body: "Add the shortcut and assign it. Klypst ticks the last step itself the first time it runs. You can finish this later from History."
            ) {
                SetupChecklistView(embedded: true)
            }
        case .privacy:
            heroPage(
                visual: .glyph("lock"),
                title: "Private by default.",
                body: "Your clipboard history stays on your iPhone. Clips you copy from Klypst don’t leave it either. No account. No tracking."
            )
        }
    }

    private enum Visual {
        case mascot
        case glyph(String)
    }

    /// A picture and a promise. Fills the page when it fits; scrolls at large type sizes.
    private func heroPage(visual: Visual, title: String, body: String) -> some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 24)
                visualView(visual)
                Spacer(minLength: 24)
                copyBlock(title: title, body: body)
                    .padding(.bottom, 24)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    visualView(visual)
                    copyBlock(title: title, body: body)
                }
                .padding(.vertical, 16)
            }
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// A title and interactive content below it, always scrollable.
    private func formPage<Content: View>(title: String, body: String, @ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                copyBlock(title: title, body: body)
                content()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private func visualView(_ visual: Visual) -> some View {
        HStack {
            Spacer()
            switch visual {
            case .mascot:
                MascotView(height: isAccessibilitySize ? 140 : 230)
                    .scaleEffect(mascotShown ? 1 : 0.9)
                    .opacity(mascotShown ? 1 : 0)
            case .glyph(let symbol):
                CardStackGlyph(symbol: symbol, size: isAccessibilitySize ? 88 : 128)
            }
            Spacer()
        }
    }

    private func copyBlock(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(isAccessibilitySize ? .title.bold() : .largeTitle.bold())
                .kerning(-0.5)
                .foregroundStyle(Color.brandInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(body)
                .font(isAccessibilitySize ? .body : .title3)
                .foregroundStyle(Color.brandInkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases, id: \.rawValue) { item in
                Capsule()
                    .fill(item.rawValue == page ? Color.accentColor : Color.brandSeparator)
                    .frame(width: item.rawValue == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : Brand.Motion.settle, value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(Step.allCases.count)")
    }
}
