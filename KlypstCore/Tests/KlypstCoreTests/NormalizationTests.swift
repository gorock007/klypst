import Foundation
import Testing
@testable import KlypstCore

@Suite("ContentNormalizer")
struct NormalizationTests {
    @Test func trimsText() {
        #expect(ContentNormalizer.normalizeText("  hello \n") == "hello")
        #expect(ContentNormalizer.normalizeText(" \n\t ") == nil)
    }

    @Test func normalizesURLs() throws {
        let url = try #require(URL(string: "HTTPS://Example.COM:443/Path?Q=1"))
        #expect(ContentNormalizer.normalizeURL(url)?.absoluteString == "https://example.com/Path?Q=1")
        let bare = try #require(URL(string: "http://example.com"))
        #expect(ContentNormalizer.normalizeURL(bare)?.absoluteString == "http://example.com/")
    }

    @Test func detectsStandaloneURL() {
        #expect(ContentNormalizer.detectStandaloneURL(in: "  https://apple.com/iphone ")?.absoluteString == "https://apple.com/iphone")
        #expect(ContentNormalizer.detectStandaloneURL(in: "see https://apple.com now") == nil)
        #expect(ContentNormalizer.detectStandaloneURL(in: "ftp://host/file") == nil)
        #expect(ContentNormalizer.detectStandaloneURL(in: "not a url") == nil)
    }

    @Test func searchKeyFoldsCaseAndDiacritics() {
        #expect(ContentNormalizer.searchKey("Crème Brûlée") == "creme brulee")
    }

    @Test func previewCollapsesLines() {
        let preview = ContentNormalizer.preview(of: "line one\n\n  line two  ")
        #expect(preview == "line one ⏎ line two")
        let long = String(repeating: "a", count: 500)
        #expect(ContentNormalizer.preview(of: long).count == ClipSummary.previewLength + 1)
    }
}

@Suite("ContentHasher")
struct HasherTests {
    @Test func isStableAndDomainSeparated() throws {
        #expect(ContentHasher.hash(text: "abc") == ContentHasher.hash(text: "abc"))
        #expect(ContentHasher.hash(text: "abc") != ContentHasher.hash(text: "abd"))
        let url = try #require(URL(string: "https://x.com/"))
        #expect(ContentHasher.hash(text: url.absoluteString) != ContentHasher.hash(url: url))
        #expect(ContentHasher.hash(text: "abc").count == 64)
    }
}

@Suite("RetentionPolicy")
struct RetentionPolicyTests {
    @Test func cutoffs() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(RetentionPolicy.never.cutoffDate(now: now) == nil)
        let cutoff = RetentionPolicy.sevenDays.cutoffDate(now: now)
        #expect(cutoff != nil)
        #expect(cutoff! < now)
        #expect(RetentionPolicy.oneDay.expirationDate(lastUsedAt: now)! > now)
    }
}
