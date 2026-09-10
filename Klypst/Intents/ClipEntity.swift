import AppIntents
import Foundation
import KlypstCore

/// Lightweight App Intents representation of a clip. Carries the preview, never image bytes.
struct ClipEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Clip")
    static let defaultQuery = ClipEntityQuery()

    let id: UUID
    let kind: ClipKind
    let preview: String
    let isPinned: Bool
    let lastUsedAt: Date
    let thumbnailURL: URL?

    init(summary: ClipSummary) {
        id = summary.id
        kind = summary.kind
        preview = summary.preview
        isPinned = summary.isPinned
        lastUsedAt = summary.lastUsedAt
        thumbnailURL = summary.thumbnailURL
    }

    var displayRepresentation: DisplayRepresentation {
        let style = ClipDisplayStyle(kind: kind, preview: preview)
        let subtitle = "\(style.displayName) • \(lastUsedAt.formatted(.relative(presentation: .named)))"
        let image: DisplayRepresentation.Image = thumbnailURL.map { .init(url: $0) } ?? .init(systemName: style.systemImageName)
        return DisplayRepresentation(
            title: "\(preview)",
            subtitle: "\(subtitle)",
            image: image
        )
    }
}

struct ClipEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [ClipEntity] {
        guard let repository = AppEnvironment.shared.repository else { return [] }
        var results: [ClipEntity] = []
        for id in identifiers {
            if let content = try await repository.clip(id: id) {
                results.append(ClipEntity(summary: content.summary))
            }
        }
        return results
    }

    @MainActor
    func suggestedEntities() async throws -> [ClipEntity] {
        guard let repository = AppEnvironment.shared.repository else { return [] }
        return try await repository.recent(limit: 10).map(ClipEntity.init(summary:))
    }

    @MainActor
    func entities(matching string: String) async throws -> [ClipEntity] {
        guard let repository = AppEnvironment.shared.repository else { return [] }
        return try await repository.search(string, pinnedOnly: false, limit: 25).map(ClipEntity.init(summary:))
    }
}
