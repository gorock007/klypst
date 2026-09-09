import Foundation

/// Resolves every on-disk location inside the shared App Group container.
///
/// ```
/// <App Group>/
///   Database/Klypst.store
///   Payloads/<clip-id>/original
///   Payloads/<clip-id>/thumbnail
///   Temp/
/// ```
public struct AppGroupPaths: Sendable, Hashable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    /// Resolves the App Group container. Throws when the entitlement is missing.
    public init(groupIdentifier: String = KlypstConfiguration.appGroupIdentifier) throws {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) else {
            throw AppGroupPathsError.containerUnavailable(groupIdentifier)
        }
        self.init(root: url)
    }

    public var databaseDirectory: URL { root.appending(path: "Database", directoryHint: .isDirectory) }
    public var databaseURL: URL { databaseDirectory.appending(path: "Klypst.store") }
    public var payloadsDirectory: URL { root.appending(path: "Payloads", directoryHint: .isDirectory) }
    public var tempDirectory: URL { root.appending(path: "Temp", directoryHint: .isDirectory) }

    public func payloadDirectory(for clipID: UUID) -> URL {
        payloadsDirectory.appending(path: clipID.uuidString, directoryHint: .isDirectory)
    }

    public func url(forRelativePath path: String) -> URL {
        root.appending(path: path)
    }

    public func relativePath(for url: URL) -> String {
        let rootPath = root.standardizedFileURL.path()
        let full = url.standardizedFileURL.path()
        guard full.hasPrefix(rootPath) else { return full }
        return String(full.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    public func ensureDirectories() throws {
        let fm = FileManager.default
        for dir in [databaseDirectory, payloadsDirectory, tempDirectory] {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }
}

public enum AppGroupPathsError: Error, Sendable {
    case containerUnavailable(String)
}
