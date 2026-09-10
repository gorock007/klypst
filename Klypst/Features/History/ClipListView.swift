import KlypstCore
import SwiftUI

struct ClipListView: View {
    @Environment(AppState.self) private var state
    @State private var model: ClipListModel
    @State private var editMode: EditMode = .inactive
    @State private var selection = Set<UUID>()
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteSelectedConfirmation = false
    /// Row briefly lifted after a copy (brand motion: "selected card subtly lifts/snaps").
    @State private var liftedID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(mode: ClipListModel.Mode) {
        _model = State(initialValue: ClipListModel(mode: mode))
    }

    private var isEditing: Bool { editMode.isEditing }

    /// Selected clips in the order they appear in the list.
    private var orderedSelection: [UUID] {
        model.items.map(\.id).filter(selection.contains)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(model.mode == .pinned ? "Pinned" : "History")
                .searchable(text: $model.query, prompt: "Search clips")
                .toolbar { toolbarContent }
                .environment(\.editMode, $editMode)
                .task(id: state.changeToken) { await model.load() }
                .task(id: model.query) { await model.search() }
                .refreshable { await model.load() }
                .onChange(of: editMode) { _, mode in
                    if !mode.isEditing { selection.removeAll() }
                }
                .navigationDestination(for: ClipSummary.self) { summary in
                    ClipDetailView(clipID: summary.id)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !model.hasLoaded {
            ProgressView()
                .accessibilityLabel("Loading clips")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .brandCanvas()
        } else if model.loadFailed {
            ContentUnavailableView("Couldn’t load clips", systemImage: "exclamationmark.triangle", description: Text("Pull to try again."))
                .brandCanvas()
        } else if model.items.isEmpty {
            emptyState
                .brandCanvas()
        } else {
            List(selection: $selection) {
                if model.mode == .history, state.showsClipboardNudge, !isEditing, !model.isSearching {
                    ClipboardNudgeCard()
                        .listRowBackground(Color.brandBackground)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .selectionDisabled()
                }
                ForEach(model.items) { summary in
                    NavigationLink(value: summary) {
                        ClipRow(summary: summary)
                    }
                    .listRowBackground(liftedID == summary.id ? Color.accentColor.opacity(0.12) : Color.brandBackground)
                    .scaleEffect(liftedID == summary.id && !reduceMotion ? 1.02 : 1)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button { copy(summary) } label: { Label("Copy", systemImage: "doc.on.doc") }
                            .tint(.accentColor)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(summary) } label: { Label("Delete", systemImage: "trash") }
                        Button { togglePin(summary) } label: {
                            Label(summary.isPinned ? "Unpin" : "Pin", systemImage: summary.isPinned ? "pin.slash" : "pin")
                        }
                        .tint(Color.brandInkSecondary)
                    }
                    .contextMenu { ClipContextMenu(summary: summary) }
                }
            }
            .listStyle(.plain)
            .brandListCanvas()
            .animation(reduceMotion ? nil : Brand.Motion.snap, value: liftedID)
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if model.isSearching {
            ContentUnavailableView.search(text: model.query)
        } else if model.mode == .pinned {
            ContentUnavailableView("Nothing pinned yet.", systemImage: "pin", description: Text("Pin a clip to keep it from expiring. It’ll show up here."))
        } else {
            EmptyHistoryView()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .topBarLeading) {
                Button(selection.count == model.items.count ? "Deselect All" : "Select All") {
                    if selection.count == model.items.count {
                        selection.removeAll()
                    } else {
                        selection = Set(model.items.map(\.id))
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { withAnimation { editMode = .inactive } }
                    .fontWeight(.semibold)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { copySelected() } label: {
                    Label("Copy \(selection.count)", systemImage: "doc.on.doc")
                }
                .disabled(selection.isEmpty)
                .accessibilityHint("Copies the selected clips as one text, one per line")
                Menu {
                    Button { pinSelected(true) } label: { Label("Pin", systemImage: "pin") }
                    Button { pinSelected(false) } label: { Label("Unpin", systemImage: "pin.slash") }
                    Divider()
                    Button(role: .destructive) { showDeleteSelectedConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .disabled(selection.isEmpty)
                .confirmationDialog("Delete \(selection.count) clips?", isPresented: $showDeleteSelectedConfirmation, titleVisibility: .visible) {
                    Button("Delete \(selection.count) Clips", role: .destructive) { deleteSelected() }
                }
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { withAnimation { editMode = .active } } label: { Label("Select Clips", systemImage: "checkmark.circle") }
                        .disabled(model.items.isEmpty)
                    NavigationLink { HelpView() } label: { Label("Help & Setup", systemImage: "questionmark.circle") }
                    if model.mode == .history {
                        Divider()
                        Button(role: .destructive) { showDeleteAllConfirmation = true } label: {
                            Label("Delete All Clips…", systemImage: "trash")
                        }
                        .disabled(model.items.isEmpty)
                    }
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

    // MARK: Actions

    private func copy(_ summary: ClipSummary) {
        lift(summary.id)
        Task {
            do {
                try await AppEnvironment.shared.copyClip(id: summary.id)
                state.showToast("Copied")
            } catch {
                state.showToast("Couldn’t copy that clip", isSuccess: false)
            }
        }
    }

    private func copySelected() {
        let ids = orderedSelection
        Task {
            do {
                let count = try await AppEnvironment.shared.copyCombined(ids: ids)
                if count == 0 {
                    state.showToast("Only text and links can be combined", isSuccess: false)
                } else {
                    state.showToast(count == 1 ? "Copied" : "Copied \(count) clips, one per line")
                    withAnimation { editMode = .inactive }
                }
            } catch {
                state.showToast("Couldn’t copy those clips", isSuccess: false)
            }
        }
    }

    private func pinSelected(_ pinned: Bool) {
        let ids = orderedSelection
        Task {
            for id in ids { try? await AppEnvironment.shared.setPinned(id: id, pinned) }
            withAnimation { editMode = .inactive }
        }
    }

    private func deleteSelected() {
        let ids = orderedSelection
        Task {
            for id in ids { try? await AppEnvironment.shared.delete(id: id) }
            state.showToast("Deleted \(ids.count) clips")
            withAnimation { editMode = .inactive }
        }
    }

    /// Lift the copied card for a beat, then let it settle.
    private func lift(_ id: UUID) {
        liftedID = id
        Task {
            try? await Task.sleep(for: .milliseconds(450))
            if liftedID == id {
                withAnimation(reduceMotion ? nil : Brand.Motion.settle) { liftedID = nil }
            }
        }
    }

    private func togglePin(_ summary: ClipSummary) {
        Task { try? await AppEnvironment.shared.setPinned(id: summary.id, !summary.isPinned) }
    }

    private func delete(_ summary: ClipSummary) {
        Task { try? await AppEnvironment.shared.delete(id: summary.id) }
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

/// Shown when the pasteboard changed since Klypst last touched it. Detection uses
/// only the change counter, so nothing is read until the user taps Save.
struct ClipboardNudgeCard: View {
    @Environment(AppState.self) private var state
    @State private var isSaving = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.on.clipboard")
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: Brand.Radius.tile, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("You copied something new")
                    .font(.subheadline.weight(.semibold))
                Text("Save it to Klypst?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Not Now") { AppEnvironment.shared.markClipboardSeen() }
                .buttonStyle(.borderless)
                .font(.subheadline)
            Button {
                save()
            } label: {
                if isSaving { ProgressView() } else { Text("Save") }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
            .accessibilityLabel("Save copied content")
        }
        .padding(12)
        .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .strokeBorder(Color.brandSeparator, lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
    }

    private func save() {
        isSaving = true
        Task {
            let outcome = await AppEnvironment.shared.saveCurrentClipboard()
            state.showToast(outcome.message, isSuccess: outcome.isSuccess)
            isSaving = false
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

/// History empty state: one of the few places the mascot appears (brand §4, §14).
struct EmptyHistoryView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ViewThatFits(in: .vertical) {
            VStack(spacing: 0) {
                Spacer()
                content
                Spacer()
                Spacer()
            }
            ScrollView {
                content.padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var content: some View {
        VStack(spacing: 0) {
            MascotView(height: dynamicTypeSize.isAccessibilitySize ? 100 : 150)
                .padding(.bottom, 28)
            Text("Nothing here yet.")
                .font(.title2.bold())
                .foregroundStyle(Color.brandInk)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Copy something and save it. It’ll be here when you need it.")
                .font(.body)
                .foregroundStyle(Color.brandInkSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.horizontal, 40)
            NavigationLink { HelpView() } label: {
                Text("Help & Setup")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .padding(.top, 20)
        }
    }
}
