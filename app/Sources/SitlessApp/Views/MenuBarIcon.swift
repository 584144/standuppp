import AppKit
import SitlessCore
import SwiftUI

struct MenuBarIcon: View {
    let fraction: Double
    let indicator: IndicatorState

    var dark: Bool = true

    private var brand: Color {
        dark
            ? Color(.sRGB, red: 0.333, green: 0.804, blue: 0.651, opacity: 1)
            : Color(.sRGB, red: 0.059, green: 0.431, blue: 0.341, opacity: 1)
    }

    private var tint: Color {
        switch indicator {
        case .idle, .quiet, .backedOff: return brand.opacity(0.4)
        default:                        return brand
        }
    }

    private var level: Double {
        switch indicator {
        case .onBreak: return 0
        case .breakDue, .escalating, .held, .backedOff: return 1
        default: return min(1, max(0, fraction))
        }
    }

    private var resting: Bool { indicator == .held }

    var body: some View {
        Group {
            if resting {
                RestingDash()
            } else {
                Ring(level: level)
            }
        }
        .frame(width: 14, height: 14)
        .foregroundStyle(tint)
        .accessibilityLabel(Text(Self.label(for: indicator)))
    }

    static func label(for indicator: IndicatorState) -> String {
        switch indicator {
        case .working:    return "sitless, working"
        case .breakDue:   return "sitless, a break is due"
        case .escalating: return "sitless, a break is overdue"
        case .held:       return "sitless, a break is due and being held for a call"
        case .backedOff:  return "sitless, a break is owed and it has stood down for now"
        case .onBreak:    return "sitless, on a break"
        case .idle:       return "sitless, idle"
        case .quiet:      return "sitless, quiet"
        }
    }
}

/// A ring that fills clockwise as the work interval runs, solid once a break is due.
private struct Ring: View {
    let level: Double

    var body: some View {
        ZStack {
            Circle().stroke(lineWidth: 1.2).opacity(0.45)
            Circle()
                .trim(from: 0, to: min(1, max(0, level)))
                .stroke(style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle().frame(width: 3, height: 3)
        }
        .padding(1.5)
    }
}

private struct RestingDash: View {
    var body: some View {
        GeometryReader { geometry in
            Capsule(style: .continuous)
                .frame(width: geometry.size.width + 1, height: 2)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.62)
        }
    }
}
