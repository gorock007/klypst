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
        #if DEBUG
        // Debug only: lets UI tests run the picker from Spotlight. In release the
        // picker is used inside a shortcut, followed by Copy to Clipboard.
        AppShortcut(
            intent: PickClipIntent(),
            phrases: ["Pick a clip in \(.applicationName)"],
            shortTitle: "Pick a Clip",
            systemImageName: "square.stack"
        )
        #endif
    }

    static let shortcutTileColor: ShortcutTileColor = .teal
}
