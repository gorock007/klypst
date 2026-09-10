import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [Page] = [
        Page(
            symbol: "clipboard",
            title: "Welcome to Klypst",
            body: "Save what you copy, find it fast, and paste it again — text, links and images."
        ),
        Page(
            symbol: "lock.iphone",
            title: "Stays on your iPhone",
            body: "No account, no cloud, no tracking. Your clips live only on this device, and you choose how long they’re kept."
        ),
        Page(
            symbol: "hand.raised",
            title: "You’re in control of capture",
            body: "iOS doesn’t let apps silently record every copy, and Klypst doesn’t try. Save with one tap, the Action Button, or the Share Sheet."
        ),
        Page(
            symbol: "button.horizontal.top.press",
            title: "One press to save, one tap to paste",
            body: "Put Klypst on the Action Button: copy anything and press to save it; press again and tap a clip to paste it anywhere. The two-minute setup is in Help."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 20) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 64))
                            .foregroundStyle(Color.accentColor)
                            .accessibilityHidden(true)
                        Text(item.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text(item.body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)
                    .tag(index)
                    .accessibilityElement(children: .combine)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if page < pages.count - 1 {
                    withAnimation(reduceMotion ? nil : .default) { page += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Open History")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)

            Button("Skip") { onFinish() }
                .padding(.top, 12)
                .padding(.bottom, 24)
                .opacity(page < pages.count - 1 ? 1 : 0)
                .accessibilityHidden(page == pages.count - 1)
        }
        .background(Color(.systemBackground))
    }

    private struct Page {
        let symbol: String
        let title: String
        let body: String
    }
}
