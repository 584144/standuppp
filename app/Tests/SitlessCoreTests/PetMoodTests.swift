import Foundation
import Testing

@testable import SitlessCore

@Suite("the desktop pet's mood follows the work clock")
struct PetMoodTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func mood(
        _ indicator: IndicatorState, _ fraction: Double = 0, last: PetMood.LastBreak? = nil
    ) -> PetMood {
        PetMood.mood(indicator: indicator, workFraction: fraction, lastBreak: last, now: now)
    }

    @Test("sitting longer makes it tired")
    func tiresAsTheClockRuns() {
        #expect(mood(.working, 0.1) == .fresh)
        #expect(mood(.working, 0.5) == .focused)
        #expect(mood(.working, 0.9) == .tired)
    }

    @Test("a due break makes it nudge, whatever stage the prompt is at")
    func nudgesWhenDue() {
        for indicator in [IndicatorState.breakDue, .escalating, .held] {
            #expect(mood(indicator, 1) == .nudging)
        }
    }

    @Test("it sleeps through a break and steps aside while you are away")
    func restsAndAway() {
        #expect(mood(.onBreak) == .resting)
        for indicator in [IndicatorState.idle, .quiet, .backedOff] {
            #expect(mood(indicator) == .away)
        }
    }

    @Test("right after a break it is proud if it counted and sulks if it was voided")
    func afterABreak() {
        let justNow = now.addingTimeInterval(-10)
        #expect(mood(.working, 0, last: .init(counted: true, endedAt: justNow)) == .proud)
        #expect(mood(.working, 0, last: .init(counted: false, endedAt: justNow)) == .sulking)
        let longAgo = now.addingTimeInterval(-PetMood.afterBreakWindow - 1)
        #expect(mood(.working, 0, last: .init(counted: false, endedAt: longAgo)) == .fresh)
    }

    @Test("a due break outranks the afterglow")
    func dueOutranksAfterglow() {
        let justNow = now.addingTimeInterval(-10)
        #expect(mood(.breakDue, 1, last: .init(counted: false, endedAt: justNow)) == .nudging)
    }
}
