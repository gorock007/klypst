import Foundation

/// Ready-made shortcuts, hosted as iCloud share links so setup is one tap instead of six steps.
///
/// To publish or update one: build the shortcut in the Shortcuts app on a device signed in
/// to the Klypst Apple Account, tap Share → Copy iCloud Link, and paste the URL here.
/// While a link is nil the Help screen shows the manual steps only.
enum KlypstLinks {
    /// Get Clipboard → Pick a Clip (Save First: Clipboard) → Copy to Clipboard.
    /// Assigned to the Action Button. Saves the last copy, then pastes any earlier clip.
    static let actionButtonShortcut: URL? = nil

    /// Pick an Image Clip → Copy to Clipboard. For Back Tap or a Control Center shortcut.
    static let imageShortcut: URL? = nil
}
