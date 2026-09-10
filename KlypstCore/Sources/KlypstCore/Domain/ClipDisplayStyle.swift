import Foundation

/// How a clip is presented. Storage only knows text, links and images; this adds a
/// display-only "code" style for text that clearly looks like a command or source code.
/// Detection is deliberately conservative: a false "Code" label is worse than a missed one.
public enum ClipDisplayStyle: String, Sendable, CaseIterable, Hashable {
    case text
    case code
    case link
    case image

    public init(kind: ClipKind, preview: String) {
        switch kind {
        case .url: self = .link
        case .image: self = .image
        case .text: self = Self.looksLikeCode(preview) ? .code : .text
        }
    }

    public var displayName: String {
        switch self {
        case .text: "Text"
        case .code: "Code"
        case .link: "Link"
        case .image: "Image"
        }
    }

    public var systemImageName: String {
        switch self {
        case .text: "doc.text"
        case .code: "curlybraces"
        case .link: "link"
        case .image: "photo"
        }
    }

    // MARK: Detection

    /// Command-line tools that rarely start an ordinary sentence.
    private static let commands: Set<String> = [
        "npm", "npx", "yarn", "pnpm", "bun", "deno", "node", "git", "gh", "brew", "pip", "pip3",
        "python3", "curl", "wget", "sudo", "docker", "kubectl", "xcodebuild", "xcrun", "swift",
        "cargo", "rustc", "ssh", "scp", "chmod", "chown", "mkdir", "vercel", "terraform", "psql",
    ]

    /// Punctuation that shows up in code and almost never in prose.
    private static let codeTokens = ["=>", "->", "::", "==", "!=", "&&", "||", "();", "{", "}", "</", "/>", "[]", "${"]

    /// Whole-clip shapes that are unambiguous: declarations, a bare import, SQL, markup.
    private static let patterns: [NSRegularExpression] = [
        #"^(func|def|fn|class|struct|enum|const|let|var|export|interface|type)\s+[A-Za-z_][A-Za-z0-9_.]*\s*(=|\(|\{|<|:\s*[A-Za-z_\[])"#,
        #"^import\s+[A-Za-z_][A-Za-z0-9_.]*;?$"#,
        #"^(import|from)\s+\S+.*\s(from|import)\s"#,
        #"^#include\s*[<"]"#,
        #"^(SELECT|INSERT INTO|UPDATE|DELETE FROM|CREATE TABLE|ALTER TABLE|DROP TABLE|WITH)\s"#,
        #"^<[A-Za-z][^>]*>.*</[A-Za-z]+>$"#,
    ].compactMap { try? NSRegularExpression(pattern: $0) }

    static func looksLikeCode(_ preview: String) -> Bool {
        let trimmed = preview.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if trimmed.hasPrefix("$ ") || trimmed.hasPrefix("#!") { return true }

        let words = trimmed.split(whereSeparator: \.isWhitespace)
        if words.count >= 2, let first = words.first, commands.contains(String(first)) {
            return true
        }

        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if patterns.contains(where: { $0.firstMatch(in: trimmed, range: range) != nil }) { return true }

        let hits = codeTokens.filter { trimmed.contains($0) }.count
        let endsLikeStatement = trimmed.hasSuffix(";") || trimmed.hasSuffix("{") || trimmed.hasSuffix("}")
        return hits >= 2 || (hits >= 1 && endsLikeStatement)
    }
}
