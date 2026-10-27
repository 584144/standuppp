import AVFoundation
import AppKit
import SitlessCore

enum PromptSound {
    static func play(for level: EscalationLevel, enabled: Bool) {
        guard enabled, let sound = NSSound(named: name(for: level)) else { return }
        sound.volume = volume(for: level)
        sound.play()
    }

    static func playBreakOver(enabled: Bool) {
        guard enabled, let sound = NSSound(named: NSSound.Name("Glass")) else { return }
        sound.volume = 0.3
        sound.play()
    }

    private static func name(for level: EscalationLevel) -> NSSound.Name {
        switch level {
        case .first:    return NSSound.Name("Tink")
        case .second:   return NSSound.Name("Morse")
        case .third:    return NSSound.Name("Submarine")
        case .incident: return NSSound.Name("Sosumi")
        }
    }

    private static func volume(for level: EscalationLevel) -> Float {
        switch level {
        case .first:    return 0.35
        case .second:   return 0.6
        case .third:    return 0.8
        case .incident: return 1
        }
    }
}

/// The first prompt of a cycle, said out loud: two synthesized quacks, a beat, then a squeaky
/// voice. The voice is macOS's own speech synthesizer, on this Mac, nothing fetched.
@MainActor
enum DuckVoice {
    private static let quack = NSSound(data: QuackSynth.wav())
    private static let speaker = AVSpeechSynthesizer()

    static func play(chinese: Bool) {
        if let quack {
            quack.volume = 0.55
            quack.stop()
            quack.play()
        }
        let line = chinese ? "你该起来动动了！" : "Time to get up and move!"
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(QuackSynth.duration + 0.2))
            let utterance = AVSpeechUtterance(string: line)
            utterance.voice = AVSpeechSynthesisVoice(language: chinese ? "zh-CN" : "en-US")
            utterance.pitchMultiplier = 1.9
            utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * 1.15)
            utterance.volume = 0.9
            speaker.stopSpeaking(at: .immediate)
            speaker.speak(utterance)
        }
    }
}
