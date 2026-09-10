import AppIntents
import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section {
                Text("Copy anything, press the Action Button to save it. Press again to pick any earlier clip and paste it — without leaving the app you’re in. Klypst can’t read or write your clipboard in the background, so the Shortcuts app does those two parts. Build this once:")
                step(1, "Open the **Shortcuts** app and tap **+** to make a new shortcut.")
                step(2, "Add **Get Clipboard**.")
                step(3, "Add **Pick a Clip** (search for Klypst). Tap the arrow to expand it and check that **Save First** shows a **Clipboard** token and **Clip** is empty. If not, tap Save First → Select Variable → Clipboard, and clear Clip.")
                step(4, "Add **Copy to Clipboard**. Its field should show the text from Pick a Clip; if not, tap it and choose that variable.")
                step(5, "Name it **Klypst** and tap Done.")
                step(6, "Go to **Settings → Action Button**, swipe to **Shortcut**, and choose the shortcut you just made.")
                ShortcutsLink()
            } header: {
                Text("Set up the Action Button")
            } footer: {
                Text("Each press saves what you last copied, then shows a list of your clips. Pick one and it’s on your clipboard; tap the same one again if you only wanted to save. The first run asks whether the shortcut may use the clipboard — choose Always Allow. Images can’t go through this recipe; save them with the Share Sheet and copy them from the Klypst app.")
            }

            Section {
                step(1, "Copy a link, a sentence, a photo — anything.")
                step(2, "Open Klypst. A **You copied something new** card appears at the top of History.")
                step(3, "Tap **Save**, or use **Save Clipboard** at the bottom any time.")
            } header: {
                Text("Without the Action Button")
            } footer: {
                Text("Klypst only notices that the clipboard changed. Nothing is read until you tap Save, and iOS may show its standard paste notice when it does.")
            }

            Section {
                Text("For the page you’re on, tap Safari’s **Share** button and choose **Klypst**. No selecting or copying needed.")
                Text("For a link inside a page, **touch and hold** it and choose **Share** → **Klypst**.")
                Text("Text you select in an address bar or a form only offers Cut, Copy and Paste. Copy it, then press the Action Button or use the card in Klypst.")
            } header: {
                Text("Links in Safari")
            }

            Section {
                step(1, "In any app, tap **Share**.")
                step(2, "Choose **Klypst** in the app row. If it’s hidden, tap **More** and enable it.")
                step(3, "The item is saved instantly and you return to where you were.")
            } header: {
                Text("Share to Klypst")
            }

            Section {
                step(1, "Press the Action Button, or run **Recent Clips** from Shortcuts, Siri or Spotlight.")
                step(2, "Tap a clip. It becomes your clipboard. If iOS blocks copying in the background, Klypst opens for a moment and says **Copied** — swipe back to the app you were in.")
                step(3, "Paste in any app.")
                Text("To send several clips at once, open Klypst, choose **Select Clips** from the ••• menu, pick them, and tap **Copy**. They’re copied as one text, one per line.")
                SiriTipView(intent: ShowRecentClipsIntent())
            } header: {
                Text("Getting clips back")
            } footer: {
                Text("Control Center controls can’t show the clip list, so use the Action Button, Siri or Shortcuts. Clips are only shown after the phone is unlocked.")
            }

            Section {
                Text("Prefer a richer list with thumbnails? Make a shortcut with **Get Clipboard**, **Save to Klypst** (Content: Clipboard) and **Recent Clips**. Tapping a clip in that list opens Klypst for a moment to copy it — iOS doesn’t allow the copy to happen in the background — then swipe back and paste.")
            } header: {
                Text("Alternative: the Klypst clip list")
            }

            Section {
                Text("Klypst adds these actions to the Shortcuts app and Siri: **Recent Clips**, **Save Clipboard**, **Pick a Clip**, **Save to Klypst**, **Copy Clip**, **Get Recent Clips** and **Get Clip Text**. All but the first two appear when you add an action and search for Klypst.")
            } header: {
                Text("Shortcuts & Siri")
            }

            Section {
                Text("iOS does not allow apps to silently record everything you copy, and Klypst doesn’t try to work around that. Every clip in Klypst is one you chose to save.")
                Text("This version does not include a custom keyboard. Copy a clip from Klypst, the Action Button, or a shortcut, then paste as usual.")
            } header: {
                Text("What Klypst doesn’t do")
            }
        }
        .navigationTitle("Help & Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .accessibilityHidden(true)
            Text(text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number)")
    }
}
