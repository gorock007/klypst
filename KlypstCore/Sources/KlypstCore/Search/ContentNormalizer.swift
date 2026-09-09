import Foundation

/// Pure normalization used for hashing, deduplication and search.
public enum ContentNormalizer {
    /// Trims surrounding whitespace/newlines. Returns nil for empty input.
    public static func normalizeText(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Lowercases scheme and host, drops default ports and empty fragments.
    /// The path, query and case-sensitive parts are preserved.
    public static func normalizeURL(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }
        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        if let port = components.port, let scheme = components.scheme {
            if (scheme == "http" && port == 80) || (scheme == "https" && port == 443) {
                components.port = nil
            }
        }
        if components.fragment?.isEmpty == true { components.fragment = nil }
        if components.path.isEmpty, components.host != nil { components.path = "/" }
        return components.url
    }

    /// Returns a web URL when the whole (trimmed) text is a single http(s) link.
    public static func detectStandaloneURL(in text: String) -> URL? {
        guard let trimmed = normalizeText(text),
              !trimmed.contains(where: \.isWhitespace),
              trimmed.count <= 2048,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host(), !host.isEmpty
        else { return nil }
        return normalizeURL(url)
    }

    /// Case- and diacritic-insensitive form used for the search index.
    public static func searchKey(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Single-line preview suitable for lists and snippets.
    public static func preview(of text: String, maxLength: Int = ClipSummary.previewLength) -> String {
        let collapsed = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ⏎ ")
        if collapsed.count <= maxLength { return collapsed }
        return String(collapsed.prefix(maxLength)) + "…"
    }
}
