import Foundation

public enum FaceMood: String, Sendable, Codable, CaseIterable, Hashable {
    case watching
    case eyebrow
    case level
    case wink
    case welcomeBack
    case resting

    public init(level: EscalationLevel, tone: Tone) {
        switch level {
        case .first: self = .watching
        case .second: self = .eyebrow
        case .third: self = tone == .friendly ? .eyebrow : .level
        case .incident: self = .wink
        }
    }

    public var spokenLabel: String {
        switch self {
        case .watching: return "standuppp, watching"
        case .eyebrow: return "standuppp, one eyebrow raised"
        case .level: return "standuppp, eyes level"
        case .wink: return "standuppp, winking"
        case .welcomeBack: return "standuppp, smiling with its eyes"
        case .resting: return "standuppp, eyes closed"
        }
    }
}
