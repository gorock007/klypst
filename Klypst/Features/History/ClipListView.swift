import KlypstCore
import SwiftUI

struct ClipListView: View {
    @Environment(AppState.self) private var state
    @State private var model: ClipListModel
    @State private var isSaving = false
    @State private var showDeleteAllConfirmation = false

    init(mode: ClipListModel.Mode) {
        _model = State(initialValue: ClipListModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(model.mode == .pinned ? "Pinned" : "History")
                .searchable(text: $model.query, prompt: "Search clips")
                .toolbar { toolbarContent }
                .task(id: state.changeToken) { await model.load() }
                .task(id: model.query) { await model.search() }
                .refreshable { await model.load() }
                .navigationDestination(for: ClipSummary.self) { summary in
                    ClipDetailView(clipID: summary.id)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !model.hasLoaded {
            ProgressView().accessibilityLabel("Loading clips")
        } else if model.loadFailed {
            ContentUnavailableView("Couldn’t Load Clips", systemImage: "exclamationmark.triangle", description: Text("Pull to try again."))
        } else if model.items.isEmpty {
            emptyState
        } else {
            List {
                ForEach(model.items) { summary in
                    NavigationLink(value: summary) {
                        ClipRow(summary: summary)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { copy(summary) } label: { Label("Copy", systemImage: "doc.on.doc") }
                            .tint(.accentColor)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(summary) } label: { Label("Delete", systemImage: "trash") }
                        Button { togglePin(summary) } label: {
                            Label(summary.isPinned ? "Unpin" : "Pin", systemImage: summary.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(.orange)
                    }
                    .contextMenu { ClipContextMenu(summary: summary) }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.isSearching {
            ContentUnavailableView.search(text: model.query)
        } else if model.mode == .pinned {
            ContentUnavailableView("No Pinned Clips", systemImage: "pin", description: Text("Pin a clip to keep it from expiring and find it here."))
        } else {
            ContentUnavailableView {
                Label("No Clips Yet", systemImage: "clipboard")
            } description: {
                Text("Copy something in any app, then tap **Save Clipboard**. You can also share text, links or images to Klypst from the Share Sheet.")
            } actions: {
                saveClipboardButton
                    .buttonStyle(.borderedProminent)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if model.mode == .history {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    NavigationLink { HelpView() } label: { Label("Help & Setup", systemImage: "questionmark.circle") }
                    Button(role: .destructive) { showDeleteAllConfirmation = true } label: {
                        Label("Delete All Clips…", systemImage: "trash")
                    }
                    .disabled(model.items.isEmpty)
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .confirmationDialog("Delete all clips?", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                    Button("Delete All Clips", role: .destructive) { deleteAll() }
                } message: {
                    Text("This permanently removes every clip, including pinned ones, from this device.")
                }
            }
        }
    }

    private var saveClipboardButton: some View {
        Button {
            saveClipboard()
        } label: {
            Label("Save Clipboard", systemImage: "doc.on.clipboard")
        }
        .disabled(isSaving)
        .accessibilityHint("Reads the current clipboard once and stores it in Klypst.")
    }

    // MARK: Actions

    private func saveClipboard() {
        guard !isSaving else { return }
        isSaving = true
        Task {
            let outcome = await AppEnvironment.shared.saveCurrentClipboard()
            state.showToast(outcome.message, isSuccess: outcome.isSuccess)
            isSaving = false
        }
    }

    private func copy(_ summary: ClipSummary) {
        Task {
            do {
                try await AppEnvironment.shared.copyClip(id: summary.id)
                state.showToast("Copied")
            } catch {
                state.showToast("Couldn’t copy that clip", isSuccess: false)
            }
        }
    }

    private func togglePin(_ summary: ClipSummary) {
        Task {
            try? await AppEnvironment.shared.setPinned(id: summary.id, !summary.isPinned)
        }
    }

    private func delete(_ summary: ClipSummary) {
        Task {
            try? await AppEnvironment.shared.delete(id: summary.id)
        }
    }

    private func deleteAll() {
        Task {
            do {
                try await AppEnvironment.shared.deleteAll()
                state.showToast("All clips deleted")
            } catch {
                state.showToast("Couldn’t delete clips", isSuccess: false)
            }
        }
    }
}

/// Shared context-menu actions for a clip.
struct ClipContextMenu: View {
    @Environment(AppState.self) private var state
    let summary: ClipSummary

    var body: some View {
        Button {
            Task {
                do {
                    try await AppEnvironment.shared.copyClip(id: summary.id)
                    state.showToast("Copied")
                } catch {
                    state.showToast("Couldn’t copy that clip", isSuccess: false)
                }
            }
        } label: { Label("Copy", systemImage: "doc.on.doc") }

        Button {
            Task { try? await AppEnvironment.shared.setPinned(id: summary.id, !summary.isPinned) }
        } label: {
            Label(summary.isPinned ? "Unpin" : "Pin", systemImage: summary.isPinned ? "pin.slash" : "pin")
        }

        Divider()

        Button(role: .destructive) {
            Task { try? await AppEnvironment.shared.delete(id: summary.id) }
        } label: { Label("Delete", systemImage: "trash") }
    }
}
