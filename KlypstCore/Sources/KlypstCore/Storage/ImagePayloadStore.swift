import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Writes image payloads and thumbnails to the App Group container.
///
/// Pipeline (architecture §15): inspect → enforce limits → downsample thumbnail
/// off the main thread → atomic write → return relative paths → clean up on failure.
/// Uses ImageIO only, so it works identically in the app and in extensions.
public struct ImagePayloadStore: Sendable {
    public struct Stored: Sendable, Hashable {
        public let originalRelativePath: String
        public let thumbnailRelativePath: String
        public let dimensions: ImageDimensions
        public let byteSize: Int
        public let contentType: UTType
    }

    public enum Failure: Error, Sendable {
        case tooLarge
        case unsupported
        case writeFailed
    }

    public static let originalFileName = "original"
    public static let thumbnailFileName = "thumbnail"

    public let paths: AppGroupPaths
    public let maxByteSize: Int
    public let maxPixelDimension: Int
    public let thumbnailMaxPixelSize: Int

    public init(
        paths: AppGroupPaths,
        maxByteSize: Int = 25 * 1024 * 1024,
        maxPixelDimension: Int = 4096,
        thumbnailMaxPixelSize: Int = 320
    ) {
        self.paths = paths
        self.maxByteSize = maxByteSize
        self.maxPixelDimension = maxPixelDimension
        self.thumbnailMaxPixelSize = thumbnailMaxPixelSize
    }

    // MARK: Inspection

    public struct Info: Sendable, Hashable {
        public let dimensions: ImageDimensions
        public let contentType: UTType
    }

    public static func inspect(_ data: Data) -> Info? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0,
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = props[kCGImagePropertyPixelWidth] as? Int,
              let height = props[kCGImagePropertyPixelHeight] as? Int
        else { return nil }
        let typeID = CGImageSourceGetType(source) as String?
        let type = typeID.flatMap(UTType.init) ?? .image
        // EXIF orientation 5–8 swap width/height for display.
        let orientation = props[kCGImagePropertyOrientation] as? UInt32 ?? 1
        let swapped = orientation >= 5
        return Info(
            dimensions: ImageDimensions(width: swapped ? height : width, height: swapped ? width : height),
            contentType: type
        )
    }

    // MARK: Writing

    /// Stores `data` for `clipID`. On any failure the clip's payload directory is removed.
    public func store(imageData data: Data, for clipID: UUID) throws -> Stored {
        guard data.count <= maxByteSize else { throw Failure.tooLarge }
        guard let info = Self.inspect(data) else { throw Failure.unsupported }

        let directory = paths.payloadDirectory(for: clipID)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            let originalURL = directory.appending(path: Self.originalFileName)
            let thumbnailURL = directory.appending(path: Self.thumbnailFileName)

            var originalData = data
            var dimensions = info.dimensions
            var contentType = info.contentType
            if max(info.dimensions.width, info.dimensions.height) > maxPixelDimension {
                guard let downsampled = Self.downsample(data, maxPixelSize: maxPixelDimension, type: .jpeg, quality: 0.9) else {
                    throw Failure.unsupported
                }
                originalData = downsampled.data
                dimensions = downsampled.dimensions
                contentType = .jpeg
            }

            guard let thumb = Self.downsample(originalData, maxPixelSize: thumbnailMaxPixelSize, type: .jpeg, quality: 0.8) else {
                throw Failure.unsupported
            }

            try originalData.write(to: originalURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            try thumb.data.write(to: thumbnailURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])

            return Stored(
                originalRelativePath: paths.relativePath(for: originalURL),
                thumbnailRelativePath: paths.relativePath(for: thumbnailURL),
                dimensions: dimensions,
                byteSize: originalData.count,
                contentType: contentType
            )
        } catch {
            try? FileManager.default.removeItem(at: directory)
            KlypstLog.storage.error("Image payload write failed: \(String(describing: type(of: error)), privacy: .public)")
            throw error
        }
    }

    public func remove(clipID: UUID) {
        let directory = paths.payloadDirectory(for: clipID)
        guard FileManager.default.fileExists(atPath: directory.path()) else { return }
        do {
            try FileManager.default.removeItem(at: directory)
        } catch {
            KlypstLog.storage.error("Failed to remove payload directory.")
        }
    }

    public func removeAll() {
        let fm = FileManager.default
        try? fm.removeItem(at: paths.payloadsDirectory)
        try? fm.removeItem(at: paths.tempDirectory)
        try? fm.createDirectory(at: paths.payloadsDirectory, withIntermediateDirectories: true)
        try? fm.createDirectory(at: paths.tempDirectory, withIntermediateDirectories: true)
    }

    /// Payload directories whose clip ID is not in `liveIDs`.
    public func orphanDirectories(liveIDs: Set<UUID>) -> [URL] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(at: paths.payloadsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return entries.filter { url in
            guard let id = UUID(uuidString: url.lastPathComponent) else { return true }
            return !liveIDs.contains(id)
        }
    }

    public func removeOrphans(liveIDs: Set<UUID>) -> Int {
        var removed = 0
        for url in orphanDirectories(liveIDs: liveIDs) {
            if (try? FileManager.default.removeItem(at: url)) != nil { removed += 1 }
        }
        return removed
    }

    // MARK: Downsampling

    struct Downsampled {
        let data: Data
        let dimensions: ImageDimensions
    }

    static func downsample(_ data: Data, maxPixelSize: Int, type: UTType, quality: Double) -> Downsampled? {
        let sourceOptions: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions as CFDictionary) else { return nil }
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type.identifier as CFString, 1, nil) else { return nil }
        let destOptions: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: quality]
        CGImageDestinationAddImage(destination, image, destOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return Downsampled(data: output as Data, dimensions: ImageDimensions(width: image.width, height: image.height))
    }
}
