import KlypstCore
import SwiftUI

/// Everything the UI says about one trigger: how to assign the Klypst shortcut to it,
/// and how to fire it. The shortcut is identical for all of them.
struct TriggerGuide {
    let trigger: CaptureTrigger
    let symbol: String
    /// One line under the name in pickers.
    let summary: String
    /// Steps to assign the shortcut, with Markdown bold.
    let steps: [String]
    /// Completes "Copy the sample, then …".
    let fireInstruction: String

    static func guide(for trigger: CaptureTrigger) -> TriggerGuide {
        switch trigger {
        case .actionButton:
            TriggerGuide(
                trigger: trigger,
                symbol: "button.horizontal.top.press",
                summary: "One press from anywhere. iPhone 15 Pro and later.",
                steps: [
                    "Open **Settings** and tap **Action Button**.",
                    "Swipe to **Shortcut** and tap **Choose a Shortcut…**.",
                    "Pick **Klypst**.",
                ],
                fireInstruction: "press the Action Button"
            )
        case .backTap:
            TriggerGuide(
                trigger: trigger,
                symbol: "hand.tap",
                summary: "Double-tap the back of your iPhone. Works with a case, on iPhone 8 and later.",
                steps: [
                    "Open **Settings → Accessibility → Touch** and tap **Back Tap** at the bottom.",
                    "Tap **Double Tap**.",
                    "Scroll to the **Shortcuts** list at the bottom and pick **Klypst**.",
                ],
                fireInstruction: "double-tap the back of your iPhone"
            )
        case .controlCenter:
            TriggerGuide(
                trigger: trigger,
                symbol: "switch.2",
                summary: "A button in Control Center, one swipe away in any app.",
                steps: [
                    "Swipe down from the top-right corner, then tap **+** in the top-left corner.",
                    "Tap **Add a Control** and search for **Shortcut**.",
                    "Tap the new control, choose **Klypst**, then tap an empty area to finish.",
                ],
                fireInstruction: "open Control Center and tap the Klypst control"
            )
        case .lockScreen:
            TriggerGuide(
                trigger: trigger,
                symbol: "lock.iphone",
                summary: "Replace the flashlight or camera button at the bottom of your Lock Screen.",
                steps: [
                    "Touch and hold your Lock Screen, tap **Customize**, then **Lock Screen**.",
                    "Tap the **flashlight** or **camera** button, remove it with **−**, then tap **+**.",
                    "Search for **Shortcut**, add it, choose **Klypst**, and tap **Done**.",
                ],
                fireInstruction: "tap the Klypst button on your Lock Screen"
            )
        case .siri:
            TriggerGuide(
                trigger: trigger,
                symbol: "waveform",
                summary: "Say the shortcut’s name. Nothing else to set up.",
                steps: [
                    "Make sure the shortcut is named **Klypst** in the Shortcuts app.",
                    "Say **“Hey Siri, Klypst”**. Siri runs it and the card appears.",
                ],
                fireInstruction: "say “Hey Siri, Klypst”"
            )
        case .homeScreen:
            TriggerGuide(
                trigger: trigger,
                symbol: "square.grid.2x2",
                summary: "An icon on your Home Screen that runs the shortcut.",
                steps: [
                    "Open **Shortcuts** and tap **⋯** on the Klypst card.",
                    "Tap the **⌄** next to its name and choose **Add to Home Screen**, then **Add**.",
                ],
                fireInstruction: "tap the Klypst icon on your Home Screen"
            )
        case .undecided:
            TriggerGuide(
                trigger: trigger,
                symbol: "questionmark.circle",
                summary: "Pick how you’ll call Klypst.",
                steps: [],
                fireInstruction: "run the Klypst shortcut"
            )
        }
    }

    /// Choices in recommendation order for this iPhone.
    static var recommendedOrder: [CaptureTrigger] {
        DeviceCapabilities.hasActionButton
            ? CaptureTrigger.choices
            : [.backTap] + CaptureTrigger.choices.filter { $0 != .backTap }
    }

    static var recommended: CaptureTrigger { recommendedOrder[0] }

    /// Shown next to a trigger this iPhone can't use.
    static func unavailableNote(for trigger: CaptureTrigger) -> String? {
        trigger == .actionButton && !DeviceCapabilities.hasActionButton ? "Not on this iPhone" : nil
    }
}

/// A numbered instruction row, shared by setup and Help.
struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .frame(width: 22, height: 22)
                .foregroundStyle(Color.brandOrangeDeep)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .accessibilityHidden(true)
            Text(LocalizedStringKey(text))
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number)")
    }
}

/// The shortcut recipe for people who prefer to build it by hand. Must mirror
/// `tools/shortcuts/build.py` `main_recipe` exactly.
struct ManualRecipeSteps: View {
    var body: some View {
        StepRow(number: 1, text: "Open the **Shortcuts** app and tap **+** to make a new shortcut.")
        StepRow(number: 2, text: "Add **Get Clipboard**.")
        StepRow(number: 3, text: "Add **Pick a Clip** (search for Klypst). Expand it: **Save First** should show the **Clipboard** token. Set **Copied Image** to the **Clipboard** variable as well, and leave **Clip** empty.")
        StepRow(number: 4, text: "Add **Copy to Clipboard** and set its field to the **Pick a Clip** variable.")
        StepRow(number: 5, text: "Name it **Klypst** and tap Done.")
    }
}
