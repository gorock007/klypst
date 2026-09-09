import Foundation

public struct ImageDimensions: Hashable, Sendable, Codable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    public var description: String { "\(width) × \(height)" }
}

/// Lightweight row used by lists, snippets and the keyboard. Never carries image bytes.
public struct ClipSummary: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let kind: ClipKind
    /// Short human-readable preview: the text (truncated), the URL, or an image description.
    public let preview: String
    public let createdAt: Date
    public let lastUsedAt: Date
    public let isPinned: Bool
    public let byteSize: Int
    public let imageDimensions: ImageDimensions?
    /// Absolute URL of the thumbnail file, when the clip is an image.
    public let thumbnailURL: URL?

    public init(
        id: UUID,
        kind: ClipKind,
        preview: String,
        createdAt: Date,
        lastUsedAt: Date,
        isPinned: Bool,
        byteSize: Int,
        imageDimensions: ImageDimensions? = nil,
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.kind = kind
        self.preview = preview
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isPinned = isPinned
        self.byteSize = byteSize
        self.imageDimensions = imageDimensions
        self.thumbnailURL = thumbnailURL
    }

    public static let previewLength = 200
}

/// Full content of a clip. Image bytes are loaded from `payloadURL` by the caller when needed.
public struct ClipContent: Identifiable, Hashable, Sendable {
    public let summary: ClipSummary
    public let text: String?
    public let url: URL?
    public let payloadURL: URL?
    public let captureMethod: CaptureMethod

    public var id: UUID { summary.id }
    public var kind: ClipKind { summary.kind }

    public init(summary: ClipSummary, text: String?, url: URL?, payloadURL: URL?, captureMethod: CaptureMethod) {
        self.summary = summary
        self.text = text
        self.url = url
        self.payloadURL = payloadURL
        self.captureMethod = captureMethod
    }
}

/// What a capture surface hands to the repository.
public struct ClipInput: Sendable {
    public enum Payload: Sendable {
        case text(String)
        case url(URL)
        case image(Data)
    }

    public let payload: Payload
    public let captureMethod: CaptureMethod

    public init(payload: Payload, captureMethod: CaptureMethod) {
        self.payload = payload
        self.captureMethod = captureMethod
    }

    public static func text(_ text: String, via method: CaptureMethod) -> ClipInput {
        ClipInput(payload: .text(text), captureMethod: method)
    }

    public static func url(_ url: URL, via method: CaptureMethod) -> ClipInput {
        ClipInput(payload: .url(url), captureMethod: method)
    }

    public static func image(_ data: Data, via method: CaptureMethod) -> ClipInput {
        ClipInput(payload: .image(data), captureMethod: method)
    }
}

public enum SaveResult: Sendable, Equatable {
    /// A new clip was stored.
    case saved(ClipSummary)
    /// An identical clip already existed; its recency was refreshed instead.
    case duplicate(ClipSummary)
    /// The content could not be stored. The reason is safe to show to the user.
    case rejected(RejectionReason)

    public enum RejectionReason: String, Sendable, Equatable {
        case empty
        case imageTooLarge
        case unsupportedImage

        public var message: String {
            switch self {
            case .empty: "There was nothing to save."
            case .imageTooLarge: "That image is too large to save."
            case .unsupportedImage: "That image format isn’t supported."
            }
        }
    }

    public var summary: ClipSummary? {
        switch self {
        case .saved(let s), .duplicate(let s): s
        case .rejected: nil
        }
    }
}
