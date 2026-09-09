import Foundation
import SwiftData

/// Single place that knows where the SwiftData store lives.
public enum SharedModelContainerFactory {
    public static let schema = Schema(versionedSchema: KlypstSchemaV1.self)

    /// Store inside the App Group so the app, Share Extension and intents share it.
    public static func makeSharedContainer(paths: AppGroupPaths) throws -> ModelContainer {
        try paths.ensureDirectories()
        let configuration = ModelConfiguration(
            "Klypst",
            schema: schema,
            url: paths.databaseURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(for: schema, migrationPlan: KlypstMigrationPlan.self, configurations: [configuration])
        } catch {
            KlypstLog.persistence.fault("Failed to open shared model container: \(String(describing: type(of: error)), privacy: .public)")
            throw error
        }
    }

    /// Volatile container for previews and tests.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration("KlypstMemory", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: KlypstMigrationPlan.self, configurations: [configuration])
    }
}
