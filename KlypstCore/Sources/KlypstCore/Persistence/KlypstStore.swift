import Foundation
import SwiftData

/// Convenience bundle every target builds once: paths + container + repository.
public struct KlypstStore: Sendable {
    public let paths: AppGroupPaths
    public let container: ModelContainer
    public let repository: SwiftDataClipRepository
    public let preferences: PreferencesStore

    public init(paths: AppGroupPaths, container: ModelContainer, preferences: PreferencesStore) {
        self.paths = paths
        self.container = container
        self.repository = SwiftDataClipRepository(modelContainer: container, paths: paths)
        self.preferences = preferences
    }

    /// Opens the shared App Group store.
    public static func shared() throws -> KlypstStore {
        let paths = try AppGroupPaths()
        let container = try SharedModelContainerFactory.makeSharedContainer(paths: paths)
        return KlypstStore(paths: paths, container: container, preferences: PreferencesStore())
    }

    /// Volatile store rooted in a temporary directory. For previews and tests.
    public static func ephemeral() throws -> KlypstStore {
        let root = FileManager.default.temporaryDirectory.appending(path: "KlypstEphemeral-\(UUID().uuidString)")
        let paths = AppGroupPaths(root: root)
        try paths.ensureDirectories()
        let container = try SharedModelContainerFactory.makeInMemoryContainer()
        return KlypstStore(paths: paths, container: container, preferences: PreferencesStore(suiteName: "KlypstEphemeral-\(UUID().uuidString)"))
    }

    public var retention: RetentionService {
        RetentionService(repository: repository, preferences: preferences)
    }
}
