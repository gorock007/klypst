import KlypstCore
import UIKit
import UniformTypeIdentifiers

/// Share Sheet entry point. Loads the single best representation of the shared
/// item, stores it in the App Group, shows a brief confirmation, and completes.
/// No UI beyond the confirmation; no marketing, ads or purchases (Guideline 4.4).
final class ShareViewController: UIViewController {
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var didStart = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        buildHUD()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStart else { return }
        didStart = true
        Task { await run() }
    }

    // MARK: Flow

    private func run() async {
        let outcome = await process()
        show(outcome)
        try? await Task.sleep(for: .milliseconds(outcome.isSuccess ? 650 : 1200))
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func process() async -> Outcome {
        let store: KlypstStore
        do {
            store = try KlypstStore.shared()
        } catch {
            KlypstLog.shareExtension.error("Share extension could not open store.")
            return .failed("Couldn’t open Klypst storage")
        }

        let providers = (extensionContext?.inputItems as? [NSExtensionItem])?
            .flatMap { $0.attachments ?? [] } ?? []

        guard let input = await SharedItemLoader.bestInput(from: providers) else {
            KlypstLog.shareExtension.info("Unsupported share type.")
            return .failed("Klypst can save text, links and images")
        }

        do {
            let result = try await store.repository.save(input)
            switch result {
            case .saved: return .saved
            case .duplicate: return .duplicate
            case .rejected(let reason): return .failed(reason.message)
            }
        } catch {
            KlypstLog.shareExtension.error("Share save failed: \(String(describing: type(of: error)), privacy: .public)")
            return .failed("Couldn’t save to Klypst")
        }
    }

    // MARK: HUD

    private enum Outcome {
        case saved, duplicate, failed(String)

        var isSuccess: Bool {
            if case .failed = self { return false }
            return true
        }

        var message: String {
            switch self {
            case .saved: "Saved to Klypst"
            case .duplicate: "Already in Klypst"
            case .failed(let message): message
            }
        }

        var symbolName: String {
            isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        }
    }

    private let hud = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let icon = UIImageView()

    private func buildHUD() {
        hud.translatesAutoresizingMaskIntoConstraints = false
        hud.layer.cornerRadius = 22
        hud.layer.cornerCurve = .continuous
        hud.clipsToBounds = true
        view.addSubview(hud)

        let stack = UIStackView(arrangedSubviews: [spinner, icon, statusLabel])
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        hud.contentView.addSubview(stack)

        spinner.startAnimating()
        icon.isHidden = true
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .title3)
        statusLabel.text = "Saving…"
        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.numberOfLines = 2
        statusLabel.textAlignment = .center

        NSLayoutConstraint.activate([
            hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hud.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hud.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48),
            stack.topAnchor.constraint(equalTo: hud.contentView.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: hud.contentView.bottomAnchor, constant: -18),
            stack.leadingAnchor.constraint(equalTo: hud.contentView.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: hud.contentView.trailingAnchor, constant: -24),
        ])
        view.accessibilityViewIsModal = true
    }

    private func show(_ outcome: Outcome) {
        spinner.stopAnimating()
        spinner.isHidden = true
        icon.isHidden = false
        icon.image = UIImage(systemName: outcome.symbolName)
        // Brand orange (#FF5A36) marks copy/save success; the catalog isn't in this target.
        icon.tintColor = outcome.isSuccess ? UIColor(red: 1.0, green: 0.353, blue: 0.212, alpha: 1) : .systemRed
        statusLabel.text = outcome.message
        UIAccessibility.post(notification: .announcement, argument: outcome.message)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(outcome.isSuccess ? .success : .warning)
    }
}

/// Picks the best supported representation from the shared item providers and
/// loads only that one. Priority: web URL → image → text.
@MainActor
enum SharedItemLoader {
    static func bestInput(from providers: [NSItemProvider]) async -> ClipInput? {
        let method: CaptureMethod = .shareExtension

        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            if let url = await loadURL(provider) {
                if url.isFileURL {
                    if let data = await loadImageData(provider) { return .image(data, via: method) }
                } else {
                    return .url(url, via: method)
                }
            }
        }
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }),
           let data = await loadImageData(provider) {
            return .image(data, via: method)
        }
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }),
           let text = await loadText(provider) {
            return .text(text, via: method)
        }
        return nil
    }

    private static func loadURL(_ provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier) { item, _ in
                let url: URL?
                switch item {
                case let value as URL: url = value
                case let data as Data: url = URL(dataRepresentation: data, relativeTo: nil)
                case let string as String: url = URL(string: string)
                default: url = nil
                }
                continuation.resume(returning: url)
            }
        }
    }

    private static func loadText(_ provider: NSItemProvider) async -> String? {
        let typeID = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) ? UTType.plainText.identifier : UTType.text.identifier
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: typeID) { item, _ in
                let text: String?
                switch item {
                case let value as String: text = value
                case let value as NSAttributedString: text = value.string
                case let data as Data: text = String(data: data, encoding: .utf8)
                case let url as URL: text = url.absoluteString
                default: text = nil
                }
                continuation.resume(returning: text)
            }
        }
    }

    private static func loadImageData(_ provider: NSItemProvider) async -> Data? {
        // Prefer a data representation of a concrete type so we keep the original bytes.
        let preferred = [UTType.png, .jpeg, .heic, .gif, .tiff, .image].first {
            provider.hasItemConformingToTypeIdentifier($0.identifier)
        } ?? .image
        let identifier = preferred.identifier

        let direct: Data? = await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, _ in
                if let data, !data.isEmpty, ImagePayloadStore.inspect(data) != nil {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        if let direct { return direct }

        // Fallback: a file URL, a UIImage object, or raw data.
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: identifier) { item, _ in
                switch item {
                case let url as URL:
                    continuation.resume(returning: try? Data(contentsOf: url))
                case let image as UIImage:
                    continuation.resume(returning: image.pngData())
                case let data as Data:
                    continuation.resume(returning: data)
                default:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
