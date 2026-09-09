import AppIntents
import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Section("Save from the clipboard") {
                step(1, "Copy text, a link or an image in any app.")
                step(2, "Open Klypst and tap **Save Clipboard**, or press the Action Button if you set it up below.")
                step(3, "iOS may show its standard paste notice the first time. That’s expected — Klypst reads the clipboard only when you ask.")
            }

            Section {
                step(1, "Open **Settings → Action Button** on your iPhone.")
                step(2, "Swipe to **Shortcut** and tap **Choose a Shortcut…**.")
                step(3, "Pick **Klypst → Show Recent Clips**.")
                step(4, "Press the Action Button anywhere. Tap a clip to make it your clipboard, then paste.")
                SiriTipView(intent: ShowRecentClipsIntent())
                ShortcutsLink()
            } header: {
                Text("Action Button")
            } footer: {
                Text("Requires an iPhone with an Action Button. Control Center controls can’t show the clip list, so use the Action Button or Shortcuts. Clips are only shown after the phone is unlocked.")
            }

            Section {
                step(1, "In any app, tap **Share**.")
                step(2, "Choose **Klypst** in the app row. If it’s hidden, tap **More** and enable it.")
                step(3, "The item is saved instantly and you return to the app you were in.")
            } header: {
                Text("Share to Klypst")
            }

            Section {
                Text("Klypst adds **Show Recent Clips**, **Save Current Clipboard** and **Copy Clip** to the Shortcuts app and Siri, so you can build your own automations.")
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
