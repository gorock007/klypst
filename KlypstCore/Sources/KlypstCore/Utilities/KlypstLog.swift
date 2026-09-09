import Foundation
import OSLog

/// Loggers for every target.
///
/// Policy (architecture §18): log events, never clip bodies. All interpolated
/// values default to `.private` redaction in OSLog; only mark a value `.public`
/// when it is a count, a kind, or a fixed string.
public enum KlypstLog {
    public static let persistence = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "persistence")
    public static let storage = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "storage")
    public static let clipboard = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "clipboard")
    public static let retention = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "retention")
    public static let intents = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "intents")
    public static let shareExtension = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "share")
    public static let app = Logger(subsystem: KlypstConfiguration.logSubsystem, category: "app")
}
