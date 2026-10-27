import Foundation
import Testing

@testable import SitlessCore

@Suite("the reminder skits")
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

    @Test("the grandpa's mushrooms are read zhǎng, but the bubble keeps 长")
    func zhangNotChang() {
        #expect(ReminderSkit.grandpa.line(chinese: true).contains("长"))
        #expect(ReminderSkit.grandpa.spokenLine(chinese: true).contains("涨，蘑菇"))
        #expect(!ReminderSkit.grandpa.spokenLine(chinese: true).contains("长"))
        #expect(ReminderSkit.commentator.spokenLine(chinese: true).contains("给他的屁股鼓掌"))
    }

    @Test("the commentator says how long you actually sat")
    func minutesInTheLine() {
        #expect(ReminderSkit.commentator.line(chinese: true, minutes: 73).contains("73分钟"))
        #expect(ReminderSkit.commentator.line(chinese: false, minutes: 73).contains("73 minutes"))
    }

    @Test("delivery stays within fifteen percent so words stay clear")
    func deliveryIsMild() {
        for skit in ReminderSkit.allCases {
            #expect(abs(skit.delivery.pitch - 1) <= 0.1501 && abs(skit.delivery.rate - 1) <= 0.1501)
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
        let size = ReminderSkit.allCases.count
        for _ in 0..<(size * 10) { drawn.append(bag.draw()) }
        for round in stride(from: 0, to: size * 10, by: size) {
            #expect(Set(drawn[round..<round + size]).count == size)
        }
        for i in 1..<drawn.count { #expect(drawn[i] != drawn[i - 1]) }
    }

    @Test("a new round that would start with the last one is turned around")
    func noRepeatAcrossRounds() {
        var bag = SkitBag(remaining: [3], last: nil)
        #expect(bag.draw() == .cat)
        let next = bag.draw { _ in [3] + ReminderSkit.allCases.map(\.rawValue).filter { $0 != 3 } }
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
