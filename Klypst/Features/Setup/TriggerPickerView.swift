import KlypstCore
import SwiftUI

/// Radio-style list of triggers. Persists the choice as soon as it is tapped.
struct TriggerPickerView: View {
    @Binding var selection: CaptureTrigger
    /// Onboarding shows the three everyday triggers; the checklist shows all of them.
    var showsAll = false

    private var choices: [CaptureTrigger] {
        let ordered = TriggerGuide.recommendedOrder
        return showsAll ? ordered : Array(ordered.prefix(3))
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(choices) { trigger in
                row(for: trigger)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Trigger")
    }

    private func row(for trigger: CaptureTrigger) -> some View {
        let guide = TriggerGuide.guide(for: trigger)
        let isSelected = selection == trigger
        let unavailable = TriggerGuide.unavailableNote(for: trigger)
        return Button {
            withAnimation(Brand.Motion.snap) { selection = trigger }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: guide.symbol)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 40, height: 40)
                    .background(
                        isSelected ? Color.accentColor : Color.accentColor.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Brand.Radius.tile, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(trigger.displayName)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.brandInk)
                        if trigger == TriggerGuide.recommended {
                            tag("Recommended", tint: Color.accentColor)
                        } else if let unavailable {
                            tag(unavailable, tint: Color.brandInkSecondary)
                        }
                    }
                    Text(guide.summary)
                        .font(.footnote)
                        .foregroundStyle(Color.brandInkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.brandSeparator)
                    .accessibilityHidden(true)
            }
            .padding(12)
            .background(Color.brandSurface, in: RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Brand.Radius.card, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.brandSeparator, lineWidth: isSelected ? 2 : 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .accessibilityLabel(Text("\(trigger.displayName). \(guide.summary)"))
        .accessibilityIdentifier("trigger-\(trigger.rawValue)")
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.12), in: Capsule())
    }
}
