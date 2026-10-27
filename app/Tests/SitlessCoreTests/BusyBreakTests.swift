import Foundation
import Testing

@testable import SitlessCore

@Suite("a break spent at the keyboard does not count")
struct BusyBreakTests {

    private static func ending(_ effects: [Effect]) -> (honored: Bool, active: TimeInterval)? {
        for effect in effects {
            if case .endBreak(_, _, let honored, _, _, let active) = effect { return (honored, active) }
        }
        return nil
    }

    private static func runBreak(typingFor typing: TimeInterval) -> (honored: Bool, active: TimeInterval)? {
        var driver = EngineHarness.Driver(settings: EngineHarness.ownerSettings)
        driver.step(action: .startBreakNow)
        var typed: TimeInterval = 0
        for _ in 0..<200 {
            driver.typingDuringBreak = typed < typing
            if driver.typingDuringBreak { driver.idleSeconds = 0; typed += EngineHarness.Driver.tick }
            if let end = ending(driver.step()) { return end }
        }
        return nil
    }

    @Test("walking away for the whole break counts")
    func walkingAwayCounts() {
        let end = Self.runBreak(typingFor: 0)
        #expect(end?.honored == true)
        #expect(end?.active == 0)
    }

    @Test("a few seconds of input, like the click that started it, still counts")
    func aFewSecondsStillCount() {
        let end = Self.runBreak(typingFor: 30)
        #expect(end?.honored == true)
    }

    @Test("more than a minute of keyboard or mouse use voids the break")
    func overAMinuteIsVoided() {
        let end = Self.runBreak(typingFor: 90)
        #expect(end?.honored == false)
        #expect((end?.active ?? 0) > 60)
    }

    @Test("a voided break leaves the work clock running")
    func voidedBreakKeepsTheClock() {
        let time = MutableTimeSource()
        var policy = BreakPolicy()
        policy.tickInterval = 5
        policy.tickTolerance = 5
        var tracker = SessionTracker(time: time, policy: policy)
        let sample = TickSample(
            idleSeconds: 0, screenLocked: false, userPaused: false,
            application: AppIdentity(bundleID: "com.apple.dt.Xcode", localizedName: "Xcode", pid: 1),
            activity: .coding, confidence: Confidence(0.9)
        )
        for _ in 0..<72 { time.advance(by: 5); _ = tracker.tick(sample) }
        let before = tracker.session.continuousActiveWork

        _ = tracker.beginBreak(origin: .accepted)
        for _ in 0..<66 { time.advance(by: 5); _ = tracker.tick(sample) }
        _ = tracker.endBreak(origin: .accepted, threshold: 5 * 60, counts: false)

        #expect(tracker.session.continuousActiveWork >= before, "a break spent typing is not a break")
        #expect(tracker.session.breakCount == 0)
    }

    @Test("a voided break is logged as one and the day counts it as abandoned")
    func voidedBreakIsAbandonedInTheRollup() {
        let lines = EventLogWriter.lines(
            for: .endBreak(
                cycle: nil, origin: .accepted, honored: false,
                elapsed: 300, threshold: 300, activeDuringBreak: 95
            ),
            at: Date(timeIntervalSince1970: 1_700_000_300),
            context: EffectLogContext(confirmedPromptCycle: nil)
        )
        let end = lines.first { $0.kind == .breakEnd }
        #expect(end?.voided == true)
        #expect(end?.activeSeconds == 95)

        let calendar = CalendarDay.utcCalendar
        let day = CalendarDay(year: 2026, month: 9, day: 22)
        let t0 = day.interval(boundaryHour: 4, calendar: calendar)?.start.addingTimeInterval(5 * 3600)
            ?? Date(timeIntervalSince1970: 1_790_000_000)
        let breakAt = t0.addingTimeInterval(30 * 60)
        let back = breakAt.addingTimeInterval(300)
        let log: [LoggedEvent] = [
            .start(at: t0),
            .focus(at: t0, app: "com.apple.dt.Xcode", activity: .coding),
            .breakBegin(at: breakAt, origin: .accepted),
            .breakEnd(
                at: back, origin: .accepted, durationSeconds: 300, thresholdSeconds: 300,
                activeSeconds: 95, voided: true
            ),
            .stop(at: back.addingTimeInterval(30 * 60)),
        ]
        let s = DailyRollup.compute(day: day, events: log, policy: .default, calendar: calendar)
        #expect(s.breakCount == 0)
        #expect(s.breaksAbandoned == 1)
    }

    @Test("the limit comes from settings and is clamped")
    func limitFromSettings() throws {
        let data = Data(#"{"maxActiveDuringBreakSeconds": 5}"#.utf8)
        let settings = try JSONDecoder().decode(SitlessSettings.self, from: data)
        #expect(settings.maxActiveDuringBreakSeconds == 10)
        #expect(BreakPolicy(settings: SitlessSettings()).maxActiveDuringBreak == 60)
    }
}
