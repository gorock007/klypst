import AppIntents
import KlypstCore
import SwiftUI

struct HelpView: View {
    @Environment(AppState.self) private var state
    @State private var progress = AppEnvironment.shared.preferences.setupProgress
    @State private var expandedTrigger: CaptureTrigger?

    private var progressLine: String {
        if progress.isComplete { return "Trigger: \(progress.trigger.displayName)" }
        if progress.trigger == .undecided { return "\(progress.completedCount) of \(SetupProgress.stepCount) done · choose a trigger" }
        return "\(progress.completedCount) of \(SetupProgress.stepCount) done · \(progress.trigger.displayName)"
    }

    var body: some View {
        List {
            Group {
                Section {
                    Text("Copy anything — text, a link or an image — and run the Klypst shortcut to save it. Run it again to pick any earlier clip and paste it, without leaving the app you’re in. Klypst can’t read or write your clipboard in the background, so the Shortcuts app does those two parts.")
                    NavigationLink {
                        SetupChecklistView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: TriggerGuide.guide(for: progress.trigger).symbol)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(progress.isComplete ? "Set up and working" : "Finish setup")
                                    .font(.body.weight(.semibold))
                                Text(progressLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityIdentifier("helpSetup")
                } header: {
                    Text("Set up the shortcut")
                } footer: {
                    Text("Each run saves what you last copied, then shows your clips on the Klypst card. Tap one, then **Copy**, and it’s on your clipboard. If you only wanted to save, just tap Copy: the top clip is what you just copied. Prefer a single tap? Set **Style** in Pick a Clip to **Quick List** for the plain system list. The first run asks whether the shortcut may use the clipboard — choose Always Allow.")
                }

                Section {
                    Text("Already using the Action Button for something else, or on an iPhone without one? Every trigger below runs the same shortcut. Pick one, or set up several.")
                    ForEach(TriggerGuide.recommendedOrder) { trigger in
                        triggerRow(trigger)
                    }
                } header: {
                    Text("Ways to run Klypst")
                } footer: {
                    Text("You can combine them: for example the Action Button in your hand and a Lock Screen button for when the phone is on the desk.")
                }

                Section {
                    Text("The Klypst shortcut already handles images: copy one, press the Action Button, and it’s saved and listed on the card with a thumbnail. Pick it later and it goes back on your clipboard ready to paste.")
                    Text("If you’d rather keep images on their own trigger, add the shortcut below and assign it to a second trigger, such as **Back Tap**. It skips text and shows only your images.")
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
                    Text("Text you select in an address bar or a form only offers Cut, Copy and Paste. Copy it, then run the Klypst shortcut or use the card in Klypst.")
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
                    step(1, "Run the Klypst shortcut, or **Recent Clips** from Shortcuts, Siri or Spotlight.")
                    step(2, "Tap a clip. It becomes your clipboard. If iOS blocks copying in the background, Klypst opens for a moment and says **Copied** — swipe back to the app you were in.")
                    step(3, "Paste in any app.")
                    Text("To send several clips at once, open Klypst, choose **Select Clips** from the ••• menu, pick them, and tap **Copy**. They’re copied as one text, one per line.")
                    SiriTipView(intent: ShowRecentClipsIntent())
                } header: {
                    Text("Getting clips back")
                } footer: {
                    Text("Clips are only shown after the phone is unlocked.")
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
        .onAppear { progress = AppEnvironment.shared.preferences.setupProgress }
        .onChange(of: state.changeToken) { _, _ in progress = AppEnvironment.shared.preferences.setupProgress }
    }

    /// One trigger, expandable to its steps, with a button that makes it the chosen one.
    private func triggerRow(_ trigger: CaptureTrigger) -> some View {
        let guide = TriggerGuide.guide(for: trigger)
        let isCurrent = progress.trigger == trigger
        return DisclosureGroup(isExpanded: Binding(
            get: { expandedTrigger == trigger },
            set: { expandedTrigger = $0 ? trigger : nil }
        )) {
            VStack(alignment: .leading, spacing: 10) {
                Text(guide.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, text in
                    StepRow(number: index + 1, text: text)
                }
                if !isCurrent {
                    Button("Use \(trigger.displayName)") {
                        AppEnvironment.shared.preferences.captureTrigger = trigger
                        AppEnvironment.shared.preferences.setupTriggerAssigned = false
                        AppEnvironment.shared.setupDidChange()
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: guide.symbol)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)
                Text(trigger.displayName)
                if isCurrent {
                    Text("Current")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                } else if let note = TriggerGuide.unavailableNote(for: trigger) {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("help-trigger-\(trigger.rawValue)")
    }

    private func step(_ number: Int, _ text: String) -> some View {
        StepRow(number: number, text: text)
    }
}
