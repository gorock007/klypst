#if canImport(UIKit)
import Foundation
import UIKit
import UniformTypeIdentifiers

/// `UIPasteboard.general` adapter. Only ever called from user-initiated paths.
public struct GeneralPasteboardClipboard: SystemClipboard {
    public init() {}

    /// What the pasteboard holds, from the `has*` flags only. Never triggers the paste notice.
    @MainActor
    public func availability() -> ClipboardAvailability {
        let pasteboard = UIPasteboard.general
        return ClipboardAvailability(
            hasText: pasteboard.hasStrings || pasteboard.hasURLs,
            hasImage: pasteboard.hasImages
        )
    }

    @MainActor
    public func readUserInitiatedContent() async throws -> ClipInput? {
        let pasteboard = UIPasteboard.general
        let method: CaptureMethod = .manualSave

        // Prefer the richest representation, and load only that one.
        if pasteboard.hasURLs, let url = pasteboard.url, !url.isFileURL {
            KlypstLog.clipboard.info("Read pasteboard URL.")
            return .url(url, via: method)
        }
        if pasteboard.hasStrings, let string = pasteboard.string, !string.isEmpty {
            KlypstLog.clipboard.info("Read pasteboard string.")
            return .text(string, via: method)
        }
        if pasteboard.hasImages {
            for type in [UTType.png, .jpeg, .heic, .gif, .tiff] {
                if let data = pasteboard.data(forPasteboardType: type.identifier), !data.isEmpty {
                    KlypstLog.clipboard.info("Read pasteboard image data.")
                    return .image(data, via: method)
                }
            }
            if let image = pasteboard.image, let data = image.pngData() {
                KlypstLog.clipboard.info("Read pasteboard image object.")
                return .image(data, via: method)
            }
        }
        KlypstLog.clipboard.info("Pasteboard held no supported content.")
        return nil
    }

    @MainActor
    public func write(_ content: ClipContent, options: PasteboardWriteOptions) throws {
        let item: [String: Any]
        switch content.kind {
        case .text:
            guard let text = content.text else { throw SystemClipboardError.payloadMissing }
            item = [UTType.utf8PlainText.identifier: text]
        case .url:
            guard let url = content.url else { throw SystemClipboardError.payloadMissing }
            // Provide both a URL and a plain-text representation so every text field accepts it.
            item = [
                UTType.url.identifier: url,
                UTType.utf8PlainText.identifier: url.absoluteString,
            ]
        case .image:
            guard let payloadURL = content.payloadURL,
                  let data = try? Data(contentsOf: payloadURL),
                  let info = ImagePayloadStore.inspect(data)
            else { throw SystemClipboardError.payloadMissing }
            item = [info.contentType.identifier: data]
        }
        UIPasteboard.general.setItems([item], options: Self.pasteboardOptions(options))
        KlypstLog.clipboard.info("Wrote clip to pasteboard (kind: \(content.kind.rawValue, privacy: .public), localOnly: \(options.isLocalOnly, privacy: .public)).")
    }

    @MainActor
    public func writeText(_ text: String, options: PasteboardWriteOptions) throws {
        guard !text.isEmpty else { throw SystemClipboardError.payloadMissing }
        UIPasteboard.general.setItems([[UTType.utf8PlainText.identifier: text]], options: Self.pasteboardOptions(options))
        KlypstLog.clipboard.info("Wrote text to pasteboard (localOnly: \(options.isLocalOnly, privacy: .public)).")
    }

    /// `localOnly` keeps the item off Universal Clipboard; `expirationDate` lets iOS
    /// clear it without Klypst having to run again.
    private static func pasteboardOptions(_ options: PasteboardWriteOptions) -> [UIPasteboard.OptionsKey: Any] {
        var result: [UIPasteboard.OptionsKey: Any] = [:]
        if options.isLocalOnly {
            result[.localOnly] = true
        }
        if let date = options.expirationDate() {
            result[.expirationDate] = date
        }
        return result
    }
}
#endif
