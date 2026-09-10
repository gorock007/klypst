import KlypstCore
import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var state
    @State private var hasCompletedOnboarding = AppEnvironment.shared.preferences.hasCompletedOnboarding

    var body: some View {
        Group {
            #if DEBUG
            if SnippetPreviewScreen.isRequested {
                SnippetPreviewScreen()
            } else {
                content
            }
            #else
            content
            #endif
        }
        .toastOverlay()
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if case .failure = AppEnvironment.shared.storeResult {
                StoreUnavailableView()
            } else if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    AppEnvironment.shared.preferences.hasCompletedOnboarding = true
                    withAnimation { hasCompletedOnboarding = true }
                }
            }
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var state
    @State private var selection: Tab = .history

    enum Tab: Hashable { case history, pinned, settings }

    var body: some View {
        TabView(selection: $selection) {
            SwiftUI.Tab("History", systemImage: "square.stack", value: .history) {
                ClipListView(mode: .history)
            }
            SwiftUI.Tab("Pinned", systemImage: "pin", value: .pinned) {
                ClipListView(mode: .pinned)
            }
            SwiftUI.Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .tabViewBottomAccessory {
            SaveClipboardAccessory()
        }
        .task(id: state.pendingAction) {
            guard let action = state.pendingAction else { return }
            state.pendingAction = nil
            switch action {
            case .saveClipboard:
                selection = .history
                let outcome = await AppEnvironment.shared.saveCurrentClipboard(via: .intent)
                state.showToast(outcome.message, isSuccess: outcome.isSuccess)
            case .showClip:
                selection = .history
            }
        }
    }
}

struct StoreUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Storage Unavailable", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text("Klypst couldn’t open its local storage. Restart the app. If this keeps happening, reinstall Klypst.")
        }
        .brandCanvas()
    }
}

/// Persistent "Save Clipboard" control above the tab bar. The only place the
/// app reads the pasteboard, and always in response to this tap.
struct SaveClipboardAccessory: View {
    @Environment(AppState.self) private var state
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @State private var isSaving = false

    var body: some View {
        Button {
            save()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.on.clipboard")
                    .font(.body.weight(.semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text("Save Clipboard")
                        .font(.body.weight(.semibold))
                    if placement != .inline {
                        Text("Reads the clipboard once, when you tap")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if isSaving {
                    ProgressView()
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isSaving)
        .accessibilityLabel("Save Clipboard")
        .accessibilityHint("Reads the current clipboard once and stores it in Klypst.")
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            let outcome = await AppEnvironment.shared.saveCurrentClipboard()
            state.showToast(outcome.message, isSuccess: outcome.isSuccess)
            isSaving = false
        }
    }
}
