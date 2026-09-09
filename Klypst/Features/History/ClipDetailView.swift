import KlypstCore
import SwiftUI

struct ClipDetailView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    let clipID: UUID

    @State private var content: ClipContent?
    @State private var image: UIImage?
    @State private var isMissing = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        Group {
            if let content {
                detail(content)
            } else if isMissing {
                ContentUnavailableView("Clip Not Found", systemImage: "questionmark.square.dashed")
            } else {
                ProgressView()
            }
        }
        .navigationTitle(content?.kind.displayName ?? "Clip")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: state.changeToken) { await load() }
        .toolbar {
            if let content {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { copy() } label: { Label("Copy", systemImage: "doc.on.doc") }
                        .buttonStyle(.glassProminent)
                        .accessibilityHint("Makes this clip your current clipboard")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { togglePin(content) } label: {
                            Label(content.summary.isPinned ? "Unpin" : "Pin", systemImage: content.summary.isPinned ? "pin.slash" : "pin")
                        }
                        shareLink(content)
                        Divider()
                        Button(role: .destructive) { showDeleteConfirmation = true } label: { Label("Delete", systemImage: "trash") }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete this clip?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Clip", role: .destructive) { delete() }
        }
    }

    @ViewBuilder
    private func detail(_ content: ClipContent) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch content.kind {
                case .text:
                    Text(content.text ?? "")
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .url:
                    if let url = content.url {
                        Link(destination: url) {
                            Label(url.absoluteString, systemImage: "safari")
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        }
                        .accessibilityHint("Opens in your browser")
                    }
                case .image:
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .accessibilityLabel("Saved image")
                    } else {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                }

                metadata(content)
            }
            .padding()
        }
    }

    private func metadata(_ content: ClipContent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Saved", value: content.summary.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Last used", value: content.summary.lastUsedAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: Int64(content.summary.byteSize), countStyle: .file))
            if let dims = content.summary.imageDimensions {
                LabeledContent("Dimensions", value: dims.description)
            }
            let policy = AppEnvironment.shared.preferences.retentionPolicy
            if content.summary.isPinned {
                LabeledContent("Expires", value: "Never (pinned)")
            } else if let expires = policy.expirationDate(lastUsedAt: content.summary.lastUsedAt) {
                LabeledContent("Expires", value: expires.formatted(date: .abbreviated, time: .omitted))
            } else {
                LabeledContent("Expires", value: "Never")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func shareLink(_ content: ClipContent) -> some View {
        switch content.kind {
        case .text:
            if let text = content.text { ShareLink(item: text) }
        case .url:
            if let url = content.url { ShareLink(item: url) }
        case .image:
            if let image {
                ShareLink(item: Image(uiImage: image), preview: SharePreview("Image", image: Image(uiImage: image)))
            }
        }
    }

    // MARK: Actions

    private func load() async {
        guard let repository = AppEnvironment.shared.repository else { isMissing = true; return }
        do {
            guard let loaded = try await repository.clip(id: clipID) else { isMissing = true; return }
            content = loaded
            if loaded.kind == .image, image == nil, let url = loaded.payloadURL {
                image = await Task.detached(priority: .userInitiated) { UIImage(contentsOfFile: url.path()) }.value
            }
        } catch {
            isMissing = true
        }
    }

    private func copy() {
        Task {
            do {
                try await AppEnvironment.shared.copyClip(id: clipID)
                state.showToast("Copied")
            } catch {
                state.showToast("Couldn’t copy that clip", isSuccess: false)
            }
        }
    }

    private func togglePin(_ content: ClipContent) {
        Task { try? await AppEnvironment.shared.setPinned(id: clipID, !content.summary.isPinned) }
    }

    private func delete() {
        Task {
            try? await AppEnvironment.shared.delete(id: clipID)
            dismiss()
        }
    }
}
