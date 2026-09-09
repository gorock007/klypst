import Foundation
import KlypstCore
import Observation

/// Drives the History and Pinned lists. Search is local, debounced and bounded.
@MainActor
@Observable
final class ClipListModel {
    enum Mode { case history, pinned }

    let mode: Mode
    var query = ""
    private(set) var items: [ClipSummary] = []
    private(set) var hasLoaded = false
    private(set) var loadFailed = false

    static let pageLimit = 200
    static let searchDebounce: Duration = .milliseconds(250)

    init(mode: Mode) {
        self.mode = mode
    }

    var isSearching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }

    func load() async {
        guard let repository = AppEnvironment.shared.repository else {
            loadFailed = true
            hasLoaded = true
            return
        }
        do {
            let results: [ClipSummary]
            if isSearching {
                results = try await repository.search(query, pinnedOnly: mode == .pinned, limit: Self.pageLimit)
            } else {
                results = mode == .pinned
                    ? try await repository.pinned(limit: Self.pageLimit)
                    : try await repository.recent(limit: Self.pageLimit)
            }
            guard !Task.isCancelled else { return }
            items = results
            loadFailed = false
        } catch {
            KlypstLog.app.error("List load failed: \(String(describing: type(of: error)), privacy: .public)")
            loadFailed = true
        }
        hasLoaded = true
    }

    /// Debounced reload for typed search.
    func search() async {
        try? await Task.sleep(for: Self.searchDebounce)
        guard !Task.isCancelled else { return }
        await load()
    }
}
