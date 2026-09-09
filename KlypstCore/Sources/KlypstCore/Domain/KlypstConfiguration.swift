import Foundation

/// Compile-time constants shared by every target.
///
/// The App Group identifier must match the `com.apple.security.application-groups`
/// entitlement in the app and every extension (see `project.yml`).
public enum KlypstConfiguration {
    public static let appGroupIdentifier = "group.com.klypst.shared"
    public static let logSubsystem = "com.klypst"
    /// Schema version written into every record. Bump alongside `KlypstMigrationPlan`.
    public static let currentSchemaVersion = 1
    /// Number of summaries shown in the App Intents snippet.
    public static let snippetClipCount = 5
}
