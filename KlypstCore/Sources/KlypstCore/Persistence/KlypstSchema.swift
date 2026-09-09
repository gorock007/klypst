import Foundation
import SwiftData

/// Versioned schema. Add a new enum (V2, …) and a migration stage rather than editing V1.
public enum KlypstSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [ClipRecord.self]
    }

    @Model
    public final class ClipRecord {
        #Unique<ClipRecord>([\.id], [\.contentHash])
        #Index<ClipRecord>([\.lastUsedAt], [\.isPinned, \.lastUsedAt], [\.contentHash])

        public var id: UUID
        public var kindRaw: String
        /// Text body, or the normalized URL string. Nil for images.
        public var text: String?
        /// Case/diacritic-folded text used for search. Image description for images.
        public var searchText: String
        public var payloadRelativePath: String?
        public var thumbnailRelativePath: String?
        public var contentHash: String
        public var createdAt: Date
        public var lastUsedAt: Date
        public var isPinned: Bool
        public var captureMethodRaw: String
        public var byteSize: Int
        public var imageWidth: Int
        public var imageHeight: Int
        public var schemaVersion: Int

        public init(
            id: UUID = UUID(),
            kind: ClipKind,
            text: String?,
            searchText: String,
            payloadRelativePath: String? = nil,
            thumbnailRelativePath: String? = nil,
            contentHash: String,
            createdAt: Date = .now,
            lastUsedAt: Date = .now,
            isPinned: Bool = false,
            captureMethod: CaptureMethod,
            byteSize: Int,
            imageWidth: Int = 0,
            imageHeight: Int = 0,
            schemaVersion: Int = KlypstConfiguration.currentSchemaVersion
        ) {
            self.id = id
            self.kindRaw = kind.rawValue
            self.text = text
            self.searchText = searchText
            self.payloadRelativePath = payloadRelativePath
            self.thumbnailRelativePath = thumbnailRelativePath
            self.contentHash = contentHash
            self.createdAt = createdAt
            self.lastUsedAt = lastUsedAt
            self.isPinned = isPinned
            self.captureMethodRaw = captureMethod.rawValue
            self.byteSize = byteSize
            self.imageWidth = imageWidth
            self.imageHeight = imageHeight
            self.schemaVersion = schemaVersion
        }
    }
}

public typealias ClipRecord = KlypstSchemaV1.ClipRecord

public enum KlypstMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [KlypstSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}

extension ClipRecord {
    var kind: ClipKind { ClipKind(rawValue: kindRaw) ?? .text }
    var captureMethod: CaptureMethod { CaptureMethod(rawValue: captureMethodRaw) ?? .unknown }
    var imageDimensions: ImageDimensions? {
        guard kind == .image, imageWidth > 0, imageHeight > 0 else { return nil }
        return ImageDimensions(width: imageWidth, height: imageHeight)
    }

    func summary(paths: AppGroupPaths) -> ClipSummary {
        let preview: String
        switch kind {
        case .text: preview = ContentNormalizer.preview(of: text ?? "")
        case .url: preview = text ?? ""
        case .image: preview = imageDimensions.map { "Image \($0.description)" } ?? "Image"
        }
        return ClipSummary(
            id: id,
            kind: kind,
            preview: preview,
            createdAt: createdAt,
            lastUsedAt: lastUsedAt,
            isPinned: isPinned,
            byteSize: byteSize,
            imageDimensions: imageDimensions,
            thumbnailURL: thumbnailRelativePath.map(paths.url(forRelativePath:))
        )
    }

    func content(paths: AppGroupPaths) -> ClipContent {
        ClipContent(
            summary: summary(paths: paths),
            text: kind == .text ? text : nil,
            url: kind == .url ? text.flatMap(URL.init(string:)) : nil,
            payloadURL: payloadRelativePath.map(paths.url(forRelativePath:)),
            captureMethod: captureMethod
        )
    }
}
