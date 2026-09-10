import AppIntents
import KlypstCore
import SwiftUI
import UIKit

// MARK: - Spike: can an App Intents extension write the pasteboard from a snippet tap?
//
// Spike C (device, 10 Sep 2026) showed iOS discards UIPasteboard writes from the
// backgrounded Klypst app process. This target runs the same flow in an
// extension process instead. If the write survives here, the Action Button can
// be: press → snippet → tap → copied, with nothing opening and no Continue.
//
// Deliberately minimal: string IDs instead of entities, no shared views, and
// diagnostics rendered straight into the snippet so the result is readable on
// the phone without a Mac attached.

/// Entry point for the Shortcuts action "Recent Clips (Spike)".
struct ShowRecentClipsSpikeIntent: AppIntent {
    static let title: LocalizedStringResource = "Recent Clips (Spike)"
    static let description = IntentDescription(
        "Spike: shows recent clips from the Klypst intents extension. Tap one to copy it.",
        categoryName: "Retrieve"
    )
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        SpikeState.reset()
        return .result(snippetIntent: RecentClipsSpikeSnippetIntent())
    }
}

/// Re-run by the system on `reload()`.
struct RecentClipsSpikeSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Recent Clips Spike Snippet"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = try KlypstStore.shared()
        let clips = try await store.repository.recent(limit: KlypstConfiguration.snippetClipCount)
        return .result(view: SpikeSnippetView(clips: clips, outcome: SpikeState.load()))
    }
}

/// Runs when a row is tapped. Writes the pasteboard from this extension process
/// and records what happened.
struct CopyClipSpikeIntent: AppIntent {
    static let title: LocalizedStringResource = "Copy Clip (Spike)"
    // Discoverable on purpose: checking whether snippet buttons can run a hidden intent.
    static let isDiscoverable = true
    static let supportedModes: IntentModes = .background
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Clip ID")
    var clipID: String

    init() {}

    init(clipID: UUID) {
        self.clipID = clipID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let started = Date()
        var outcome = SpikeOutcome(clipID: clipID, process: ProcessInfo.processInfo.processName)
        defer {
            SpikeState.save(outcome)
            RecentClipsSpikeSnippetIntent.reload()
        }

        guard let id = UUID(uuidString: clipID) else { outcome.note = "Bad clip ID"; return .result() }
        let store: KlypstStore
        do {
            store = try KlypstStore.shared()
        } catch {
            outcome.note = "Store unavailable: \(type(of: error))"
            return .result()
        }
        guard let content = try await store.repository.clip(id: id) else {
            outcome.note = "Clip not found"
            return .result()
        }

        let pasteboard = UIPasteboard.general
        outcome.changeCountBefore = pasteboard.changeCount
        do {
            try GeneralPasteboardClipboard().write(content)
        } catch {
            outcome.note = "Write threw: \(type(of: error))"
            return .result()
        }
        outcome.changeCountAfter = pasteboard.changeCount
        outcome.wroteKind = content.kind.rawValue

        // Read back what the pasteboard now holds. Reading content this process
        // just wrote shows no paste banner; a banner here would itself mean the
        // write was discarded and we are reading someone else's content.
        switch content.kind {
        case .text:
            outcome.readBackMatches = pasteboard.string == content.text
        case .url:
            outcome.readBackMatches = pasteboard.url == content.url || pasteboard.string == content.url?.absoluteString
        case .image:
            outcome.readBackMatches = pasteboard.hasImages
        }
        outcome.elapsedMilliseconds = Int(Date().timeIntervalSince(started) * 1000)
        try? await store.repository.markUsed(id: id)
        KlypstLog.intents.info("Spike copy: process=\(outcome.process, privacy: .public) match=\(String(describing: outcome.readBackMatches), privacy: .public)")
        return .result()
    }
}

/// App Shortcut so the spike can be assigned to the Action Button directly
/// (Settings → Action Button → Shortcut → Klypst → Spike Clips) and run from
/// Spotlight, bypassing the Shortcuts-app result sheet.
struct SpikeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowRecentClipsSpikeIntent(),
            phrases: ["Spike clips in \(.applicationName)"],
            shortTitle: "Spike Clips",
            systemImageName: "testtube.2"
        )
    }
}

// MARK: - State

struct SpikeOutcome: Codable {
    var clipID: String
    var process: String
    var wroteKind: String?
    var changeCountBefore: Int?
    var changeCountAfter: Int?
    var readBackMatches: Bool?
    var elapsedMilliseconds: Int?
    var note: String?

    var summary: String {
        if let note { return note }
        var parts: [String] = []
        if let before = changeCountBefore, let after = changeCountAfter { parts.append("changeCount \(before)→\(after)") }
        if let readBackMatches { parts.append(readBackMatches ? "read-back OK" : "read-back MISMATCH") }
        if let elapsedMilliseconds { parts.append("\(elapsedMilliseconds) ms") }
        parts.append("in \(process)")
        return parts.joined(separator: " · ")
    }
}

/// Persisted in the App Group so the result survives if the system restarts the
/// extension process between the tap and the snippet reload.
@MainActor
enum SpikeState {
    private static let key = "spike.lastCopy"
    private static var defaults: UserDefaults? { UserDefaults(suiteName: KlypstConfiguration.appGroupIdentifier) }

    static func save(_ outcome: SpikeOutcome) {
        defaults?.set(try? JSONEncoder().encode(outcome), forKey: key)
    }

    static func load() -> SpikeOutcome? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SpikeOutcome.self, from: data)
    }

    static func reset() {
        defaults?.removeObject(forKey: key)
    }
}

// MARK: - View

struct SpikeSnippetView: View {
    let clips: [ClipSummary]
    let outcome: SpikeOutcome?

    private let orange = Color(red: 1.0, green: 0.353, blue: 0.212)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Klypst · extension spike")
                .font(.headline)
            Text("Tap a clip, then paste somewhere else to verify.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if clips.isEmpty {
                Text("No clips saved yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(clips) { clip in
                let copied = outcome?.clipID == clip.id.uuidString
                Button(intent: CopyClipSpikeIntent(clipID: clip.id)) {
                    HStack(spacing: 10) {
                        Image(systemName: clip.kind.systemImageName)
                            .frame(width: 24)
                            .foregroundStyle(copied ? orange : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(clip.preview).lineLimit(1)
                            Text(clip.kind.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if copied {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(orange)
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Divider()
            }

            if let outcome {
                Text(outcome.summary)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
