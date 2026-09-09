import CryptoKit
import Foundation

/// Stable content hash used for deduplication. Domain-separated by kind so a
/// text clip whose body happens to equal a URL string never collides with it.
public enum ContentHasher {
    public static func hash(text: String) -> String {
        digest(prefix: "text:", body: Data(text.utf8))
    }

    public static func hash(url: URL) -> String {
        digest(prefix: "url:", body: Data(url.absoluteString.utf8))
    }

    public static func hash(imageData: Data) -> String {
        digest(prefix: "image:", body: imageData)
    }

    private static func digest(prefix: String, body: Data) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(prefix.utf8))
        hasher.update(data: body)
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
