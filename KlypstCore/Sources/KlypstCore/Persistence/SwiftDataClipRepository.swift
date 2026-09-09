import Foundation
import SwiftData

/// SwiftData-backed repository. Runs on its own serial executor and treats the
/// store as multi-process shared state: short transactions, refetch before
/// mutations, unique-constraint handling for races.
public actor SwiftDataClipRepository: ClipRepository, ModelActor {
    public nonisolated let modelExecutor: any ModelExecutor
    public nonisolated let modelContainer: ModelContainer

    private let paths: AppGroupPaths
    private let payloadStore: ImagePayloadStore

    public init(modelContainer: ModelContainer, paths: AppGroupPaths) {
        let context = ModelContext(modelContainer)
        context.autosaveEnabled = false
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.modelContainer = modelContainer
        self.paths = paths
        self.payloadStore = ImagePayloadStore(paths: paths)
    }

    // MARK: Reads

    public func recent(limit: Int) throws -> [ClipSummary] {
        var descriptor = FetchDescriptor<ClipRecord>(sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)])
        descriptor.fetchLimit = max(0, limit)
        return try fetchSummaries(descriptor)
    }

    public func pinned(limit: Int) throws -> [ClipSummary] {
        var descriptor = FetchDescriptor<ClipRecord>(
            predicate: #Predicate { $0.isPinned },
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(0, limit)
        return try fetchSummaries(descriptor)
    }

    public func search(_ query: String, pinnedOnly: Bool, limit: Int) throws -> [ClipSummary] {
        let key = ContentNormalizer.searchKey(query)
        guard !key.isEmpty else {
            return pinnedOnly ? try pinned(limit: limit) : try recent(limit: limit)
        }
        let predicate: Predicate<ClipRecord> = pinnedOnly
            ? #Predicate { $0.isPinned && $0.searchText.contains(key) }
            : #Predicate { $0.searchText.contains(key) }
        var descriptor = FetchDescriptor<ClipRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(0, limit)
        return try fetchSummaries(descriptor)
    }

    public func clip(id: UUID) throws -> ClipContent? {
        try fetchRecord(id: id)?.content(paths: paths)
    }

    public func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<ClipRecord>())
    }

    // MARK: Writes

    public func save(_ input: ClipInput) throws -> SaveResult {
        let now = Date.now
        let prepared: PreparedClip
        switch input.payload {
        case .text(let raw):
            guard let text = ContentNormalizer.normalizeText(raw) else { return .rejected(.empty) }
            if let url = ContentNormalizer.detectStandaloneURL(in: text) {
                prepared = .link(url)
            } else {
                prepared = .text(text)
            }
        case .url(let url):
            guard let normalized = ContentNormalizer.normalizeURL(url) else { return .rejected(.empty) }
            prepared = .link(normalized)
        case .image(let data):
            guard !data.isEmpty else { return .rejected(.empty) }
            prepared = .image(data)
        }

        // Dedupe: identical content refreshes recency instead of duplicating.
        if let existing = try fetchRecord(contentHash: prepared.contentHash) {
            existing.lastUsedAt = now
            try modelContext.save()
            KlypstLog.persistence.info("Duplicate clip refreshed (kind: \(existing.kindRaw, privacy: .public)).")
            return .duplicate(existing.summary(paths: paths))
        }

        let record: ClipRecord
        switch prepared {
        case .text(let text):
            record = ClipRecord(
                kind: .text,
                text: text,
                searchText: ContentNormalizer.searchKey(text),
                contentHash: prepared.contentHash,
                createdAt: now,
                lastUsedAt: now,
                captureMethod: input.captureMethod,
                byteSize: text.utf8.count
            )
        case .link(let url):
            let string = url.absoluteString
            record = ClipRecord(
                kind: .url,
                text: string,
                searchText: ContentNormalizer.searchKey(string),
                contentHash: prepared.contentHash,
                createdAt: now,
                lastUsedAt: now,
                captureMethod: input.captureMethod,
                byteSize: string.utf8.count
            )
        case .image(let data):
            let id = UUID()
            let stored: ImagePayloadStore.Stored
            do {
                stored = try payloadStore.store(imageData: data, for: id)
            } catch ImagePayloadStore.Failure.tooLarge {
                return .rejected(.imageTooLarge)
            } catch ImagePayloadStore.Failure.unsupported {
                return .rejected(.unsupportedImage)
            }
            record = ClipRecord(
                id: id,
                kind: .image,
                text: nil,
                searchText: ContentNormalizer.searchKey("image \(stored.dimensions.description) \(stored.contentType.preferredFilenameExtension ?? "")"),
                payloadRelativePath: stored.originalRelativePath,
                thumbnailRelativePath: stored.thumbnailRelativePath,
                contentHash: prepared.contentHash,
                createdAt: now,
                lastUsedAt: now,
                captureMethod: input.captureMethod,
                byteSize: stored.byteSize,
                imageWidth: stored.dimensions.width,
                imageHeight: stored.dimensions.height
            )
        }

        modelContext.insert(record)
        do {
            try modelContext.save()
        } catch {
            // Another process may have inserted the same hash between our fetch and save.
            modelContext.rollback()
            if record.kind == .image { payloadStore.remove(clipID: record.id) }
            if let existing = try fetchRecord(contentHash: prepared.contentHash) {
                existing.lastUsedAt = now
                try? modelContext.save()
                return .duplicate(existing.summary(paths: paths))
            }
            KlypstLog.persistence.error("Clip save failed: \(String(describing: type(of: error)), privacy: .public)")
            throw error
        }
        KlypstLog.persistence.info("Clip save succeeded (kind: \(record.kindRaw, privacy: .public)).")
        return .saved(record.summary(paths: paths))
    }

    public func markUsed(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { throw ClipRepositoryError.notFound }
        record.lastUsedAt = .now
        try modelContext.save()
    }

    public func setPinned(id: UUID, _ pinned: Bool) throws {
        guard let record = try fetchRecord(id: id) else { throw ClipRepositoryError.notFound }
        record.isPinned = pinned
        try modelContext.save()
    }

    public func delete(id: UUID) throws {
        guard let record = try fetchRecord(id: id) else { return }
        let isImage = record.kind == .image
        modelContext.delete(record)
        try modelContext.save()
        if isImage { payloadStore.remove(clipID: id) }
        KlypstLog.persistence.info("Clip deleted.")
    }

    public func deleteAll() throws {
        try modelContext.delete(model: ClipRecord.self)
        try modelContext.save()
        payloadStore.removeAll()
        KlypstLog.persistence.info("All clips deleted.")
    }

    @discardableResult
    public func purgeExpired(policy: RetentionPolicy) throws -> Int {
        var purged = 0
        if let cutoff = policy.cutoffDate() {
            let descriptor = FetchDescriptor<ClipRecord>(
                predicate: #Predicate { !$0.isPinned && $0.lastUsedAt < cutoff }
            )
            let expired = try modelContext.fetch(descriptor)
            let imageIDs = expired.filter { $0.kind == .image }.map(\.id)
            for record in expired { modelContext.delete(record) }
            if !expired.isEmpty { try modelContext.save() }
            for id in imageIDs { payloadStore.remove(clipID: id) }
            purged = expired.count
        }

        // Orphan sweep: payload directories without a live record.
        var liveDescriptor = FetchDescriptor<ClipRecord>(predicate: #Predicate { $0.kindRaw == "image" })
        liveDescriptor.propertiesToFetch = [\.id]
        let liveIDs = Set(try modelContext.fetch(liveDescriptor).map(\.id))
        let orphans = payloadStore.removeOrphans(liveIDs: liveIDs)

        if purged > 0 || orphans > 0 {
            KlypstLog.retention.info("Purged \(purged, privacy: .public) expired clips and \(orphans, privacy: .public) orphaned payloads.")
        }
        return purged
    }

    // MARK: Helpers

    private enum PreparedClip {
        case text(String)
        case link(URL)
        case image(Data)

        var contentHash: String {
            switch self {
            case .text(let text): ContentHasher.hash(text: text)
            case .link(let url): ContentHasher.hash(url: url)
            case .image(let data): ContentHasher.hash(imageData: data)
            }
        }
    }

    private func fetchSummaries(_ descriptor: FetchDescriptor<ClipRecord>) throws -> [ClipSummary] {
        try modelContext.fetch(descriptor).map { $0.summary(paths: paths) }
    }

    private func fetchRecord(id: UUID) throws -> ClipRecord? {
        var descriptor = FetchDescriptor<ClipRecord>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func fetchRecord(contentHash: String) throws -> ClipRecord? {
        var descriptor = FetchDescriptor<ClipRecord>(predicate: #Predicate { $0.contentHash == contentHash })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
