import Foundation

/// Ready-made shortcuts, hosted as iCloud share links so setup is one tap instead of six steps.
///
/// To publish or update one: build the shortcut in the Shortcuts app on a device signed in
/// to the Klypst Apple Account, tap Share → Copy iCloud Link, and paste the URL here.
/// While a link is nil the Help screen shows the manual steps only.
enum KlypstLinks {
    /// The one-press recipe for the Action Button (text, links and images):
    /// Get Clipboard → Get Images from Input → If images: Pick a Clip (Save Image First) /
    /// Otherwise: Pick a Clip (Save First: Clipboard) → If result has any value: Copy to Clipboard.
    /// iCloud links are snapshots: after changing the shortcut, share it again and replace the URL.
    static let actionButtonShortcut: URL? = URL(string: "https://www.icloud.com/shortcuts/19bbb43d509a41b79a772394531d95eb")

    /// Pick an Image Clip → Copy to Clipboard. Optional: pastes an image without opening
    /// Klypst, for Back Tap or a Control Center shortcut button.
    static let imageShortcut: URL? = URL(string: "https://www.icloud.com/shortcuts/41380939ae51405f958fe4af6be01063")
}
