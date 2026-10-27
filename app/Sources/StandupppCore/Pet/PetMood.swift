import Foundation

/// How the desktop pet looks right now. A pure function of what the menu bar already knows,
/// so the pet never has an opinion the rest of the app does not.
public enum PetMood: String, Sendable, CaseIterable, Hashable {
    /// Early in a stretch: bright eyes, a little bounce.
    case fresh
    /// Halfway: calm, blinking, minding its own business.
    case focused
    /// Close to the limit: droopy eyes, slower.
    case tired
    /// A break is due: hopping and asking you to get up.
    case nudging
    /// On a break: asleep.
    case resting
    /// A break that counted just ended.
    case proud
    /// A break was voided because the keyboard kept going.
    case sulking
    /// You are away, paused, or in quiet hours.
    case away

    /// How long the pet stays proud or sulking after a break ends.
    public static let afterBreakWindow: TimeInterval = 90

    public struct LastBreak: Sendable, Hashable {
        public var counted: Bool
        public var endedAt: Date
        public init(counted: Bool, endedAt: Date) {
            self.counted = counted
            self.endedAt = endedAt
        }
    }

    /// How long the pet says something after a break ends.
    public static let afterBreakLineWindow: TimeInterval = 6

    /// Whether the pet says anything at all. It talks only when there is something to remind
    /// you of: a due break, for as long as it is due, or the few seconds after one ends.
    public static func speaks(_ mood: PetMood, lastBreak: LastBreak?, now: Date) -> Bool {
        switch mood {
        case .nudging:
            return true
        case .proud, .sulking:
            guard let lastBreak else { return false }
            let since = now.timeIntervalSince(lastBreak.endedAt)
            return since >= 0 && since < afterBreakLineWindow
        case .fresh, .focused, .tired, .resting, .away:
            return false
        }
    }

    public static func mood(
        indicator: IndicatorState,
        workFraction: Double,
        lastBreak: LastBreak?,
        now: Date
    ) -> PetMood {
        switch indicator {
        case .onBreak:
            return .resting
        case .breakDue, .escalating, .held:
            return .nudging
        case .idle, .quiet, .backedOff:
            return .away
        case .working:
            break
        }
        if let lastBreak, now.timeIntervalSince(lastBreak.endedAt) < afterBreakWindow,
           now >= lastBreak.endedAt {
            return lastBreak.counted ? .proud : .sulking
        }
        switch workFraction {
        case ..<0.4: return .fresh
        case ..<0.8: return .focused
        default: return .tired
        }
    }
}
