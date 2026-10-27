import Foundation
import Testing

@testable import SitlessCore

@Suite("the synthesized quack")
struct QuackSynthTests {
    @Test("it is short, loud enough to hear and never clips")
    func levels() {
        let s = QuackSynth.samples()
        #expect(abs(Double(s.count) / Double(QuackSynth.sampleRate) - QuackSynth.duration) < 0.01)
        let peak = s.map(abs).max() ?? 0
        #expect(peak > 0.7 && peak <= 0.8001)
        let rms = (s.map { $0 * $0 }.reduce(0, +) / Double(s.count)).squareRoot()
        #expect(rms > 0.05, "rms \(rms)")
        #expect(QuackSynth.duration < 0.6)
    }

    @Test("the WAV header describes the samples that follow")
    func header() {
        let wav = QuackSynth.wav()
        #expect(wav.prefix(4) == Data("RIFF".utf8))
        #expect(wav.subdata(in: 8..<12) == Data("WAVE".utf8))
        #expect(wav.count == 44 + QuackSynth.samples().count * 2)
    }
}
