import AppIntents

/// App Shortcuts surfaced to Siri, Spotlight, the Shortcuts app and the Action Button.
struct KlypstShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowRecentClipsIntent(),
            phrases: [
                "Show recent clips in \(.applicationName)",
                "Show my \(.applicationName) clips",
                "Open \(.applicationName) clipboard",
            ],
            shortTitle: "Recent Clips",
            systemImageName: "clipboard"
        )
        AppShortcut(
            intent: SaveCurrentClipboardIntent(),
            phrases: [
                "Save clipboard to \(.applicationName)",
                "Save my clipboard in \(.applicationName)",
            ],
            shortTitle: "Save Clipboard",
            systemImageName: "doc.on.clipboard"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .teal
}
