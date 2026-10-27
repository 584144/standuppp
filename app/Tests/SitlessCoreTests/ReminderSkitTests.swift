import Foundation
import Testing

@testable import SitlessCore

@Suite("the ten reminder skits")
struct ReminderSkitTests {
    @Test("every sound is short, audible and does not clip")
    func soundsAreSane() {
        for skit in ReminderSkit.allCases {
            for (name, s) in [("intro", skit.intro), ("outro", skit.outro)] {
                let seconds = Double(s.count) / Double(Synth.sampleRate)
                #expect(seconds > 0.2 && seconds < 2.5, "\(skit) \(name) lasts \(seconds)s")
                let n = Synth.normalised(s, peak: 0.7)
                let rms = (n.map { $0 * $0 }.reduce(0, +) / Double(n.count)).squareRoot()
                #expect(rms > 0.03, "\(skit) \(name) is nearly silent")
                #expect((n.map(abs).max() ?? 0) <= 0.7001)
            }
        }
    }

    @Test("every skit has a Chinese and an English line")
    func lines() {
        for skit in ReminderSkit.allCases {
            #expect(skit.line(chinese: true).unicodeScalars.contains { $0.value >= 0x4E00 })
            #expect(!skit.line(chinese: false).isEmpty)
        }
    }

    @Test("the WAV header describes the samples")
    func wav() {
        let data = ReminderSkit.duck.introWAV
        #expect(data.prefix(4) == Data("RIFF".utf8))
        #expect(data.count == 44 + ReminderSkit.duck.intro.count * 2)
    }

    @Test("the bag plays all ten before repeating, and never the same one twice running")
    func shuffleBag() {
        var bag = SkitBag()
        var drawn: [ReminderSkit] = []
        for _ in 0..<100 { drawn.append(bag.draw()) }
        for round in stride(from: 0, to: 100, by: 10) {
            #expect(Set(drawn[round..<round + 10]).count == 10)
        }
        for i in 1..<drawn.count { #expect(drawn[i] != drawn[i - 1]) }
    }

    @Test("a new round that would start with the last one is turned around")
    func noRepeatAcrossRounds() {
        var bag = SkitBag(remaining: [3], last: nil)
        #expect(bag.draw() == .cat)
        let next = bag.draw { _ in [3, 1, 2, 4, 5, 6, 7, 8, 9, 10] }
        #expect(next != .cat)
    }

    @Test("a saved bag survives a round trip")
    func codable() throws {
        var bag = SkitBag()
        _ = bag.draw()
        let back = try JSONDecoder().decode(SkitBag.self, from: JSONEncoder().encode(bag))
        #expect(back == bag)
    }
}
