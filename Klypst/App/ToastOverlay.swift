import SwiftUI

/// Brief, accessible confirmation shown after copy/save actions.
struct ToastOverlayModifier: ViewModifier {
    @Environment(AppState.self) private var state
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let toast = state.toast {
                    HStack(spacing: 8) {
                        Image(systemName: toast.isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(toast.isSuccess ? Color.accentColor : Color.red)
                        Text(toast.message)
                    }
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .glassEffect(.regular, in: .capsule)
                        .padding(.bottom, 132)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(toast.message)
                        .accessibilityIdentifier("toast")
                        .task(id: toast.id) {
                            AccessibilityNotification.Announcement(toast.message).post()
                            try? await Task.sleep(for: .seconds(2.2))
                            if state.toast?.id == toast.id { state.toast = nil }
                        }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: state.toast)
            .sensoryFeedback(trigger: state.toast) { _, new in
                guard let new else { return nil }
                return new.isSuccess ? .success : .warning
            }
    }
}

extension View {
    func toastOverlay() -> some View { modifier(ToastOverlayModifier()) }
}
