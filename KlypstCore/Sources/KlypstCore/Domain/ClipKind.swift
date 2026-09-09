import Foundation

public enum ClipKind: String, Codable, Sendable, CaseIterable, Hashable {
    case text
    case url
    case image

    public var displayName: String {
        switch self {
        case .text: "Text"
        case .url: "Link"
        case .image: "Image"
        }
    }

    public var systemImageName: String {
        switch self {
        case .text: "text.alignleft"
        case .url: "link"
        case .image: "photo"
        }
    }
}

/// How a clip entered the store. Never records the source app.
public enum CaptureMethod: String, Codable, Sendable, Hashable {
    case manualSave
    case shareExtension
    case intent
    case keyboard
    case unknown
}
