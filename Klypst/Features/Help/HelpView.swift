import AppIntents
import SwiftUI

struct HelpView: View {
    var body: some View {
        List {
            Group {
                Section {
                    Text("Copy anything — text, a link or an image — and press the Action Button to save it. Press again to pick any earlier clip and paste it, without leaving the app you’re in. Klypst can’t read or write your clipboard in the background, so the Shortcuts app does those two parts.")
                    if let file = KlypstLinks.actionButtonShortcutFile {
                        ShareLink(item: file, preview: SharePreview("Klypst shortcut", image: Image(.mascotSmall))) {
                            Label("Add the Klypst shortcut", systemImage: "plus.app")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.brandPrimary)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .accessibilityHint("Shares the ready-made shortcut. Choose Shortcuts in the sheet, then tap Add Shortcut.")
                        step(1, "In the sheet, choose **Shortcuts**, then tap **Add Shortcut**.")
                        step(2, "Go to **Settings → Action Button**, swipe to **Shortcut**, and choose **Klypst**.")
                        if let link = KlypstLinks.actionButtonShortcut {
                            Link("Shortcuts not in the sheet? Open the iCloud link instead.", destination: link)
                                .font(.subheadline)
                        }
                        DisclosureGroup("Or build it yourself") {
                            manualRecipeSteps
                        }
                    } else {
                        Text("Build this once:")
                        manualRecipeSteps
                        step(9, "Go to **Settings → Action Button**, swipe to **Shortcut**, and choose the shortcut you just made.")
                        ShortcutsLink()
                    }
                } header: {
                    Text("Set up the Action Button")
                } footer: {
                    Text("Each press saves what you last copied, then shows your clips on the Klypst card. Tap one, then **Copy**, and it’s on your clipboard. If you only wanted to save, just tap Copy: the top clip is what you just copied. Prefer a single tap? Set **Style** in Pick a Clip to **Quick List** for the plain system list. The first run asks whether the shortcut may use the clipboard — choose Always Allow.")
                }

                Section {
                    Text("The Action Button shortcut saves images too, and lists them on the card with a thumbnail. When you pick an image, Klypst opens for a moment to put it on your clipboard — iOS doesn’t let Shortcuts receive an image from the picker — then swipe back and paste.")
                    Text("Prefer images without opening Klypst? Add a second shortcut, **Pick an Image Clip** followed by **Copy to Clipboard**, and run it from **Back Tap** (Settings → Accessibility → Touch) or a Control Center shortcut button.")
                    if let file = KlypstLinks.imageShortcutFile {
                        ShareLink(item: file, preview: SharePreview("Klypst Images shortcut", image: Image(.mascotSmall))) {
                            Label("Add the image shortcut", systemImage: "photo.badge.plus")
                        }
                        .accessibilityHint("Shares the ready-made shortcut. Choose Shortcuts in the sheet, then tap Add Shortcut.")
                    }
                } header: {
                    Text("Images")
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
                    Text("Klypst adds these actions to the Shortcuts app and Siri: **Recent Clips**, **Save Clipboard**, **Pick a Clip**, **Pick an Image Clip**, **Save to Klypst**, **Copy Clip**, **Get Recent Clips**, **Get Clip Text** and **Get Clip Image**. All but the first two appear when you add an action and search for Klypst.")
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
            .listRowBackground(Color.brandSurface)
        }
        .brandGroupedCanvas()
        .navigationTitle("Help & Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The Action Button recipe, for people who prefer to build it by hand. Mirrors
    /// `KlypstLinks.actionButtonShortcut` exactly.
    @ViewBuilder
    private var manualRecipeSteps: some View {
        step(1, "Open the **Shortcuts** app and tap **+** to make a new shortcut.")
        step(2, "Add **Get Clipboard**.")
        step(3, "Add **Get Images from Input** and set its input to the **Clipboard** variable. It returns the image if one was copied, and nothing otherwise.")
        step(4, "Add **If**. Set its input to **Images from Input** and the condition to **has any value**.")
        step(5, "Inside the If, add **Pick a Clip** (search for Klypst). Expand it: set **Save Image First** to **Images from Input**, and leave **Save First** and **Clip** empty.")
        step(6, "Under **Otherwise**, add another **Pick a Clip**. Expand it: set **Save First** to the **Clipboard** variable, and leave **Clip** empty.")
        step(7, "After **End If**, add another **If**: input **If Result**, condition **has any value**. Inside it add **Copy to Clipboard** and set it to **If Result**.")
        step(8, "Name it **Klypst** and tap Done.")
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .foregroundStyle(Color.brandOrangeDeep)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .accessibilityHidden(true)
            Text(text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number)")
    }
}
