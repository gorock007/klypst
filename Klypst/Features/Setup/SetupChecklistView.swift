import KlypstCore
import SwiftUI

/// The three things that make Klypst one press away, kept until they are done:
/// add the shortcut, assign it to a trigger, see it run once. The last step is ticked by
/// Klypst itself, because the picker intent runs inside this process and records it.
/// Shown inside onboarding, from History's "Finish setting up" card, Settings and Help.
struct SetupChecklistView: View {
    @Environment(AppState.self) private var state
    @Environment(\.openURL) private var openURL
    /// Onboarding embeds the checklist under its own title; elsewhere it is a screen.
    var embedded = false

    @State private var progress = AppEnvironment.shared.preferences.setupProgress
    @State private var trigger = AppEnvironment.shared.preferences.captureTrigger
    @State private var showsManualRecipe = false
    @State private var showsTriggerPicker = false
    @State private var sampleCopied = false

    private var preferences: PreferencesStore { AppEnvironment.shared.preferences }
    private var guide: TriggerGuide { TriggerGuide.guide(for: trigger) }

    var body: some View {
        Group {
            if embedded {
                content
            } else {
                ScrollView {
                    content
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                }
                .brandGroupedCanvas()
                .navigationTitle("Setup")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: state.changeToken) { _, _ in refresh() }
        .onChange(of: trigger) { _, newValue in
            preferences.captureTrigger = newValue
            showsTriggerPicker = newValue == .undecided
            AppEnvironment.shared.setupDidChange()
        }
    }

    private var content: some View {
        VStack(spacing: 14) {
            progressHeader
            addShortcutCard
            assignCard
            tryItCard
        }
    }

    private func refresh() {
        progress = preferences.setupProgress
        trigger = preferences.captureTrigger
        showsTriggerPicker = trigger == .undecided
    }

    // MARK: Progress

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(progress.isComplete ? "All set" : "\(progress.completedCount) of \(SetupProgress.stepCount) done")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandInk)
                Spacer()
                if progress.isComplete, let at = preferences.lastShortcutRunAt {
                    Text("Last run \(at.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(Color.brandInkSecondary)
                }
            }
            HStack(spacing: 6) {
                ForEach(0..<SetupProgress.stepCount, id: \.self) { index in
                    Capsule()
                        .fill(index < progress.completedCount ? Color.accentColor : Color.brandSeparator)
                        .frame(height: 6)
                }
            }
            .animation(Brand.Motion.settle, value: progress.completedCount)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("setupProgress")
    }

    // MARK: Step 1

    private var addShortcutCard: some View {
        stepCard(number: 1, title: "Add the Klypst shortcut", done: progress.shortcutAdded, toggle: { done in
            preferences.setupShortcutAdded = done
            AppEnvironment.shared.setupDidChange()
        }) {
            Text("It saves what you copied, shows your clips, and copies the one you pick. Klypst can’t touch the clipboard in the background, so the Shortcuts app does that part.")
                .font(.subheadline)
                .foregroundStyle(Color.brandInkSecondary)
            if let file = KlypstLinks.actionButtonShortcutFile {
                ShareLink(item: file, preview: SharePreview("Klypst shortcut", image: Image(.mascotSmall))) {
                    Label("Add the shortcut", systemImage: "plus.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.brandPrimary)
                .simultaneousGesture(TapGesture().onEnded {
                    preferences.setupShortcutAdded = true
                    AppEnvironment.shared.setupDidChange()
                })
                .accessibilityHint("Shares the ready-made shortcut. Choose Shortcuts in the sheet, then tap Add Shortcut.")
                .accessibilityIdentifier("addShortcut")
                Text("In the sheet, choose **Shortcuts**, then tap **Add Shortcut**.")
                    .font(.footnote)
                    .foregroundStyle(Color.brandInkSecondary)
            }
            if let link = KlypstLinks.actionButtonShortcut {
                Link("Shortcuts not in the sheet? Use the iCloud link.", destination: link)
                    .font(.footnote)
            }
            DisclosureGroup("Or build it yourself", isExpanded: $showsManualRecipe) {
                VStack(alignment: .leading, spacing: 10) {
                    ManualRecipeSteps()
                }
                .font(.subheadline)
                .padding(.top, 8)
            }
            .font(.footnote.weight(.medium))
            .tint(Color.brandInkSecondary)
        }
    }

    // MARK: Step 2

    private var assignCard: some View {
        let title = trigger == .undecided ? "Choose how you’ll call it" : "Assign it to \(trigger.displayName)"
        return stepCard(number: 2, title: title, done: progress.triggerAssigned, toggle: { done in
            preferences.setupTriggerAssigned = done
            AppEnvironment.shared.setupDidChange()
        }) {
            if showsTriggerPicker {
                TriggerPickerView(selection: $trigger, showsAll: true)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: guide.symbol)
                        .foregroundStyle(Color.accentColor)
                    Text(guide.summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.brandInkSecondary)
                    Spacer(minLength: 8)
                    Button("Change") { withAnimation(Brand.Motion.snap) { showsTriggerPicker = true } }
                        .font(.subheadline.weight(.semibold))
                        .accessibilityIdentifier("changeTrigger")
                }
                ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                    StepRow(number: index + 1, text: step)
                        .font(.subheadline)
                }
                if trigger == .actionButton {
                    Text("Action Button already busy? Tap Change: Back Tap and Control Center run the same shortcut.")
                        .font(.footnote)
                        .foregroundStyle(Color.brandInkSecondary)
                }
                if !progress.triggerAssigned {
                    Button {
                        preferences.setupTriggerAssigned = true
                        AppEnvironment.shared.setupDidChange()
                    } label: {
                        Text("I’ve done this")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                    .accessibilityIdentifier("markAssigned")
                }
            }
        }
    }

    // MARK: Step 3

    private var tryItCard: some View {
        stepCard(number: 3, title: progress.hasRun ? "It works" : "Try it once", done: progress.hasRun, toggle: nil) {
            if progress.hasRun {
                Text("Klypst saw the shortcut run. From now on, copy anything and \(guide.fireInstruction) to save it, or to pick an earlier clip and paste it.")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandInkSecondary)
            } else {
                Text("Copy the sample below, then \(guide.fireInstruction). The Klypst card should appear with the sample on top. This step ticks itself.")
                    .font(.subheadline)
                    .foregroundStyle(Color.brandInkSecondary)
                Button {
                    copySample()
                } label: {
                    Label(sampleCopied ? "Sample copied. Now \(guide.fireInstruction)." : "Copy a sample", systemImage: sampleCopied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.accentColor)
                .accessibilityIdentifier("copySample")
                if let run = KlypstLinks.runShortcut {
                    Button {
                        if !sampleCopied { copySample() }
                        openURL(run)
                    } label: {
                        Text("Or run it from here (opens Shortcuts)")
                            .font(.footnote.weight(.medium))
                    }
                    .accessibilityIdentifier("runFromHere")
                }
                if sampleCopied {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Waiting for the first run…")
                            .font(.footnote)
                            .foregroundStyle(Color.brandInkSecondary)
                    }
                }
            }
        }
    }

    private func copySample() {
        let environment = AppEnvironment.shared
        do {
            try environment.clipboard.writeText("Hello from Klypst 👋 Pick me on the card, then tap Copy.", options: environment.preferences.pasteboardWriteOptions)
            environment.markClipboardSeen()
            withAnimation(Brand.Motion.snap) { sampleCopied = true }
        } catch {
            state.showToast("Couldn’t copy the sample", isSuccess: false)
        }
    }

    // MARK: Card chrome

    private func stepCard<Content: View>(
        number: Int,
        title: String,
        done: Bool,
        toggle: ((Bool) -> Void)?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    toggle?(!done)
                } label: {
                    Image(systemName: done ? "checkmark.circle.fill" : "\(number).circle")
                        .font(.title2)
                        .foregroundStyle(done ? Color.accentColor : Color.brandInkSecondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .disabled(toggle == nil)
                .accessibilityLabel(done ? "Done" : "Not done")
                .accessibilityHint(toggle == nil ? "" : "Marks this step as done or not done.")
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.brandInk)
                    .strikethrough(done, color: Color.brandInkSecondary)
                Spacer(minLength: 0)
            }
            content()
        }
        .padding(16)
        .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                .strokeBorder(Color.brandSeparator, lineWidth: 1)
        }
        .animation(Brand.Motion.settle, value: done)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("setupStep\(number)")
    }
}

/// The nudge at the top of History until setup is proven. Dismissable with Later.
struct SetupCard: View {
    @Environment(AppState.self) private var state
    @State private var progress = AppEnvironment.shared.preferences.setupProgress

    private var nextStep: String {
        if !progress.shortcutAdded { return "Add the Klypst shortcut" }
        if !progress.triggerAssigned {
            let trigger = progress.trigger
            return trigger == .undecided ? "Choose a trigger" : "Assign it to \(trigger.displayName)"
        }
        return "Run it once"
    }

    var body: some View {
        NavigationLink {
            SetupChecklistView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: Brand.Radius.tile, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Finish setting up Klypst")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandInk)
                    Text("\(progress.completedCount) of \(SetupProgress.stepCount) done · \(nextStep)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Later") {
                    AppEnvironment.shared.preferences.hasDismissedSetupCard = true
                    AppEnvironment.shared.setupDidChange()
                }
                .buttonStyle(.borderless)
                .font(.subheadline)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .strokeBorder(Color.brandSeparator, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: state.changeToken) { _, _ in progress = AppEnvironment.shared.preferences.setupProgress }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("setupCard")
    }
}
