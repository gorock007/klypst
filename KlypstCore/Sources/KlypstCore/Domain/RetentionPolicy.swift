import Foundation

/// How long an unpinned clip is kept after it was last used.
public enum RetentionPolicy: Int, CaseIterable, Sendable, Codable, Identifiable {
    case oneDay = 1
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90
    case never = 0

    public static let `default`: RetentionPolicy = .thirtyDays

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .oneDay: "1 day"
        case .sevenDays: "7 days"
        case .thirtyDays: "30 days"
        case .ninetyDays: "90 days"
        case .never: "Never delete"
        }
    }

    public var durationDays: Int? { self == .never ? nil : rawValue }

    /// Date at which a clip last used at `date` expires, or nil if it never expires.
    public func expirationDate(lastUsedAt date: Date) -> Date? {
        guard let days = durationDays else { return nil }
        return Calendar.current.date(byAdding: .day, value: days, to: date)
    }

    /// Clips last used before this instant are expired.
    public func cutoffDate(now: Date = .now) -> Date? {
        guard let days = durationDays else { return nil }
        return Calendar.current.date(byAdding: .day, value: -days, to: now)
    }
}
