import Foundation

/// How long a clip copied from Klypst stays on the system pasteboard.
///
/// Backed by `UIPasteboard.OptionsKey.expirationDate`; iOS removes the item itself.
public enum PasteboardExpiry: Int, CaseIterable, Sendable, Codable, Identifiable {
    case never = 0
    case oneMinute = 60
    case tenMinutes = 600
    case oneHour = 3600

    public static let `default`: PasteboardExpiry = .never

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .never: "Never"
        case .oneMinute: "1 minute"
        case .tenMinutes: "10 minutes"
        case .oneHour: "1 hour"
        }
    }

    public var duration: TimeInterval? { self == .never ? nil : TimeInterval(rawValue) }
}

/// Options applied to every pasteboard write Klypst performs.
///
/// `isLocalOnly` maps to `UIPasteboard.OptionsKey.localOnly`: when true the item is
/// never handed to Universal Clipboard, so a clip copied from Klypst stays on this
/// iPhone. That is the default, because "local only" should mean what it says.
public struct PasteboardWriteOptions: Sendable, Hashable {
    public var isLocalOnly: Bool
    public var expiry: PasteboardExpiry

    public init(isLocalOnly: Bool = true, expiry: PasteboardExpiry = .default) {
        self.isLocalOnly = isLocalOnly
        self.expiry = expiry
    }

    public static let `default` = PasteboardWriteOptions()

    /// Absolute expiration for an item written at `now`, or nil to keep it until replaced.
    public func expirationDate(now: Date = .now) -> Date? {
        expiry.duration.map { now.addingTimeInterval($0) }
    }
}
