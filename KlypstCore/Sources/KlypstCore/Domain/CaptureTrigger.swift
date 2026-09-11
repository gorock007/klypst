import Foundation

/// How the user chose to run the Klypst shortcut. The shortcut itself is the same for
/// every trigger; only the system setting that launches it differs.
public enum CaptureTrigger: String, CaseIterable, Codable, Sendable, Identifiable {
    case actionButton
    case backTap
    case controlCenter
    case lockScreen
    case siri
    case homeScreen
    /// Nothing chosen yet. The setup checklist asks again.
    case undecided

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .actionButton: "Action Button"
        case .backTap: "Back Tap"
        case .controlCenter: "Control Center"
        case .lockScreen: "Lock Screen button"
        case .siri: "Siri"
        case .homeScreen: "Home Screen icon"
        case .undecided: "Not chosen yet"
        }
    }

    /// Triggers a person can pick, in the order they are offered.
    public static let choices: [CaptureTrigger] = [.actionButton, .backTap, .controlCenter, .lockScreen, .siri, .homeScreen]
}

/// Where the first-run setup stands. Three steps: add the shortcut, assign a trigger,
/// see it run once. The last one is proven by the picker intent itself, so it also
/// implies the first two.
public struct SetupProgress: Equatable, Sendable {
    public var shortcutAdded: Bool
    public var triggerAssigned: Bool
    public var hasRun: Bool
    public var trigger: CaptureTrigger

    public init(shortcutAdded: Bool, triggerAssigned: Bool, hasRun: Bool, trigger: CaptureTrigger) {
        self.shortcutAdded = shortcutAdded || hasRun
        self.triggerAssigned = triggerAssigned || hasRun
        self.hasRun = hasRun
        self.trigger = trigger
    }

    public static let stepCount = 3

    public var completedCount: Int {
        [shortcutAdded, triggerAssigned, hasRun].filter { $0 }.count
    }

    public var isComplete: Bool { hasRun }
}
