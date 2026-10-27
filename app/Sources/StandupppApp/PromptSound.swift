import AVFoundation
import AppKit
import StandupppCore

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

/// The first prompt of a cycle, acted out: an opening sound, a line spoken by the Mac's own
/// voice, a closing sound. Which of the ten comes from a shuffle bag kept in UserDefaults, so
/// every one plays before any repeats, across restarts too.
@MainActor
enum SkitPlayer {
    private static let bagKey = "reminderSkitBag"
    private static let speaker = AVSpeechSynthesizer()
    private static let finisher = Finisher()
    private static var outro: NSSound?

    /// Plays the next skit and returns the line it speaks, for the pet's bubble.
    @discardableResult
    static func playNext(chinese: Bool, minutes: Int = 50) -> String {
        var bag = loadBag()
        let skit = bag.draw()
        saveBag(bag)
        play(skit, chinese: chinese, minutes: minutes)
        return skit.line(chinese: chinese, minutes: minutes)
    }

    static func play(_ skit: ReminderSkit, chinese: Bool, minutes: Int = 50) {
        speaker.stopSpeaking(at: .immediate)
        let intro = NSSound(data: skit.introWAV)
        intro?.volume = 0.6
        intro?.play()
        outro = NSSound(data: skit.outroWAV)
        outro?.volume = 0.6
        let introLength = Double(skit.intro.count) / 22_050.0
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(introLength + 0.25))
            let utterance = AVSpeechUtterance(string: skit.spokenLine(chinese: chinese, minutes: minutes))
            utterance.voice = voice(chinese: chinese, male: skit.prefersMaleVoice)
            utterance.pitchMultiplier = Float(skit.delivery.pitch)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float(skit.delivery.rate)
            utterance.volume = 0.95
            speaker.delegate = finisher
            finisher.then = {
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(0.2))
                    outro?.play()
                }
            }
            speaker.speak(utterance)
        }
    }

    /// The best installed voice for the line: an enhanced or premium male voice for the roles
    /// that want one, when the Mac has one, otherwise the clearest voice for the language.
    static func voice(chinese: Bool, male: Bool) -> AVSpeechSynthesisVoice? {
        let language = chinese ? "zh-CN" : "en-US"
        let voices = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language && !$0.identifier.contains("eloquence") }
            .sorted { $0.quality.rawValue > $1.quality.rawValue }
        if male, let man = voices.first(where: { $0.gender == .male && $0.quality != .default }) {
            return man
        }
        return voices.first ?? AVSpeechSynthesisVoice(language: language)
    }

    private static func loadBag() -> SkitBag {
        guard let data = UserDefaults.standard.data(forKey: bagKey),
              let bag = try? JSONDecoder().decode(SkitBag.self, from: data) else { return SkitBag() }
        return bag
    }

    private static func saveBag(_ bag: SkitBag) {
        if let data = try? JSONEncoder().encode(bag) { UserDefaults.standard.set(data, forKey: bagKey) }
    }

    private final class Finisher: NSObject, AVSpeechSynthesizerDelegate {
        nonisolated(unsafe) var then: (() -> Void)?

        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            let next = then
            then = nil
            next?()
        }
    }
}

