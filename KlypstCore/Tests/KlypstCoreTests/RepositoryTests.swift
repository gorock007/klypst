import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import KlypstCore

@Suite("SwiftDataClipRepository")
struct RepositoryTests {
    private func makeStore() throws -> KlypstStore {
        try KlypstStore.ephemeral()
    }

    /// A small solid PNG generated with CoreGraphics so tests need no fixtures.
    private func makePNG(width: Int = 640, height: Int = 480) throws -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try #require(CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let output = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return output as Data
    }

    @Test func savesTextAndListsRecent() async throws {
        let store = try makeStore()
        let result = try await store.repository.save(.text("hello world", via: .manualSave))
        guard case .saved(let summary) = result else { Issue.record("expected saved"); return }
        #expect(summary.kind == .text)
        #expect(summary.preview == "hello world")

        let recent = try await store.repository.recent(limit: 10)
        #expect(recent.count == 1)
        #expect(recent.first?.id == summary.id)
        #expect(try await store.repository.count() == 1)
    }

    @Test func promotesStandaloneURLTextToLink() async throws {
        let store = try makeStore()
        let result = try await store.repository.save(.text("https://Apple.com/iphone", via: .shareExtension))
        #expect(result.summary?.kind == .url)
        #expect(result.summary?.preview == "https://apple.com/iphone")
        let content = try await store.repository.clip(id: result.summary!.id)
        #expect(content?.url?.absoluteString == "https://apple.com/iphone")
    }

    @Test func rejectsEmptyText() async throws {
        let store = try makeStore()
        let result = try await store.repository.save(.text("   \n", via: .manualSave))
        #expect(result == .rejected(.empty))
    }

    @Test func dedupesIdenticalContentAndRefreshesRecency() async throws {
        let store = try makeStore()
        let first = try await store.repository.save(.text("same", via: .manualSave))
        try await Task.sleep(for: .milliseconds(20))
        let second = try await store.repository.save(.text("  same  ", via: .intent))
        guard case .saved(let a) = first, case .duplicate(let b) = second else {
            Issue.record("expected saved then duplicate"); return
        }
        #expect(a.id == b.id)
        #expect(b.lastUsedAt > a.lastUsedAt)
        #expect(try await store.repository.count() == 1)
    }

    @Test func pinSearchDelete() async throws {
        let store = try makeStore()
        let repo = store.repository
        let alpha = try await repo.save(.text("Alpha Crème", via: .manualSave)).summary!
        _ = try await repo.save(.text("beta", via: .manualSave))
        try await repo.setPinned(id: alpha.id, true)

        #expect(try await repo.pinned(limit: 10).map(\.id) == [alpha.id])
        #expect(try await repo.search("creme", pinnedOnly: false, limit: 10).map(\.id) == [alpha.id])
        #expect(try await repo.search("beta", pinnedOnly: true, limit: 10).isEmpty)
        #expect(try await repo.search("", pinnedOnly: false, limit: 10).count == 2)

        try await repo.delete(id: alpha.id)
        #expect(try await repo.count() == 1)
        #expect(try await repo.clip(id: alpha.id) == nil)
    }

    @Test func storesImageWithThumbnailAndCleansUpOnDelete() async throws {
        let store = try makeStore()
        let png = try makePNG()
        let result = try await store.repository.save(.image(png, via: .shareExtension))
        guard case .saved(let summary) = result else { Issue.record("expected saved"); return }
        #expect(summary.kind == .image)
        #expect(summary.imageDimensions == ImageDimensions(width: 640, height: 480))
        let thumbnailURL = try #require(summary.thumbnailURL)
        #expect(FileManager.default.fileExists(atPath: thumbnailURL.path()))
        let thumbInfo = try #require(ImagePayloadStore.inspect(try Data(contentsOf: thumbnailURL)))
        #expect(max(thumbInfo.dimensions.width, thumbInfo.dimensions.height) <= 320)

        let content = try #require(try await store.repository.clip(id: summary.id))
        let payloadURL = try #require(content.payloadURL)
        #expect(try Data(contentsOf: payloadURL) == png)

        // Same bytes → duplicate, no second directory.
        let dup = try await store.repository.save(.image(png, via: .manualSave))
        guard case .duplicate = dup else { Issue.record("expected duplicate"); return }

        try await store.repository.delete(id: summary.id)
        #expect(!FileManager.default.fileExists(atPath: store.paths.payloadDirectory(for: summary.id).path()))
    }

    @Test func rejectsOversizedAndInvalidImages() async throws {
        let store = try makeStore()
        let garbage = Data(repeating: 0x41, count: 1024)
        #expect(try await store.repository.save(.image(garbage, via: .manualSave)) == .rejected(.unsupportedImage))
        let huge = Data(count: 26 * 1024 * 1024)
        #expect(try await store.repository.save(.image(huge, via: .manualSave)) == .rejected(.imageTooLarge))
        #expect(store.payloadStore_orphanCount == 0)
    }

    @Test func purgeExpiredKeepsPinnedAndRemovesOrphans() async throws {
        let store = try makeStore()
        let repo = store.repository
        let old = try await repo.save(.text("old", via: .manualSave)).summary!
        let pinnedOld = try await repo.save(.text("pinned old", via: .manualSave)).summary!
        let fresh = try await repo.save(.text("fresh", via: .manualSave)).summary!
        try await repo.setPinned(id: pinnedOld.id, true)
        try await repo._backdate(ids: [old.id, pinnedOld.id], to: Date.now.addingTimeInterval(-40 * 86_400))

        // Orphan payload directory with no record.
        let orphan = store.paths.payloadDirectory(for: UUID())
        try FileManager.default.createDirectory(at: orphan, withIntermediateDirectories: true)

        let purged = try await repo.purgeExpired(policy: .thirtyDays)
        #expect(purged == 1)
        let remaining = try await repo.recent(limit: 10).map(\.id)
        #expect(Set(remaining) == Set([pinnedOld.id, fresh.id]))
        #expect(!FileManager.default.fileExists(atPath: orphan.path()))

        #expect(try await repo.purgeExpired(policy: .never) == 0)
    }

    @Test func deleteAllRemovesRecordsAndFiles() async throws {
        let store = try makeStore()
        _ = try await store.repository.save(.text("a", via: .manualSave))
        let image = try await store.repository.save(.image(try makePNG(), via: .manualSave)).summary!
        try await store.repository.deleteAll()
        #expect(try await store.repository.count() == 0)
        #expect(!FileManager.default.fileExists(atPath: store.paths.payloadDirectory(for: image.id).path()))
        #expect(FileManager.default.fileExists(atPath: store.paths.payloadsDirectory.path()))
    }

    @Test func retentionServiceThrottles() async throws {
        let store = try makeStore()
        store.preferences.retentionPolicy = .oneDay
        let clip = try await store.repository.save(.text("stale", via: .manualSave)).summary!
        try await store.repository._backdate(ids: [clip.id], to: Date.now.addingTimeInterval(-3 * 86_400))
        store.preferences.lastPurgeAt = .now
        #expect(await store.retention.runIfNeeded() == 0)
        #expect(await store.retention.runIfNeeded(force: true) == 1)
        store.preferences.reset()
    }
}

extension KlypstStore {
    var payloadStore_orphanCount: Int {
        ImagePayloadStore(paths: paths).orphanDirectories(liveIDs: []).count
    }
}
