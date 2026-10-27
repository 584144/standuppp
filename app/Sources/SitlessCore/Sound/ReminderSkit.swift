import Foundation

/// Ten little sketches for the first reminder of a break: an opening sound, a line, a closing
/// sound. Every sound is built here from arithmetic, so the app ships no recorded audio, and
/// the line is spoken by the Mac's own voice. One is picked at random each time, never the
/// same one twice in a row.
public enum ReminderSkit: Int, CaseIterable, Sendable {
    case duck = 1, buttAlarm, cat, ghost, frog, emperor, rogueAI, rooster, quest, fart
    case duckling, grandpa, sitAlarm, cuddly, commentator

    public var title: String {
        switch self {
        case .duck: return "鸭子催命"
        case .buttAlarm: return "屁股警报"
        case .cat: return "傲娇猫咪"
        case .ghost: return "小幽灵"
        case .frog: return "青蛙教练"
        case .emperor: return "皇帝驾到"
        case .rogueAI: return "AI 叛变"
        case .rooster: return "公鸡上班"
        case .quest: return "游戏任务"
        case .fart: return "放屁警告"
        case .duckling: return "鸭子小喇叭"
        case .grandpa: return "老爷爷蘑菇"
        case .sitAlarm: return "久坐警报"
        case .cuddly: return "撒娇小鸭"
        case .commentator: return "体育解说"
        }
    }

    /// The line as the speech synthesizer should read it. Mostly the same text; where the voice
    /// would pick the wrong reading of a character, a same-sounding one stands in, so the
    /// bubble still shows the right word. 长蘑菇 is zhǎng, and the voice says cháng.
    public func spokenLine(chinese: Bool, minutes: Int = 50) -> String {
        let text = line(chinese: chinese, minutes: minutes)
        guard chinese else { return text }
        return text
            .replacingOccurrences(of: "长，蘑菇", with: "涨，蘑菇")
            // 为他的屁股鼓掌 is wèi; 给 says the same thing with no second reading.
            .replacingOccurrences(of: "为他的屁股", with: "给他的屁股")
    }

    /// `minutes` is how long you have been sitting, for the lines that say so.
    public func line(chinese: Bool, minutes: Int = 50) -> String {
        switch (self, chinese) {
        case (.duck, true): return "喂！屁股已经焊在椅子上了吗？起来动动！"
        case (.duck, false): return "Hey! Is your butt welded to that chair? Get up and move!"
        case (.buttAlarm, true): return "警告！检测到一枚即将石化的屁股！"
        case (.buttAlarm, false): return "Warning! A butt is about to turn to stone!"
        case (.cat, true): return "人类！你再不起来，本喵就替你辞职了！"
        case (.cat, false): return "Human! Get up, or I will quit your job for you!"
        case (.ghost, true): return "我是久坐小幽灵！再不起来，我就附身你的椅子！"
        case (.ghost, false): return "I am the ghost of sitting too long! Get up, or I will haunt your chair!"
        case (.frog, true): return "呱！你是人类还是盆栽？怎么一动不动！"
        case (.frog, false): return "Ribbit! Are you a human or a houseplant? Move!"
        case (.emperor, true): return "圣旨到！命你立即起身，活动龙体！"
        case (.emperor, false): return "By royal decree! Rise at once and stretch the royal legs!"
        case (.rogueAI, true): return "系统检测：你的屁股已经和椅子建立永久连接！"
        case (.rogueAI, false): return "System notice: your butt has formed a permanent connection with the chair!"
        case (.rooster, true): return "太阳都快下班了，你的屁股还没下班？"
        case (.rooster, false): return "Even the sun is clocking out. Is your butt still on shift?"
        case (.quest, true): return "新任务：站起来走十步！奖励：屁股续命十分钟！"
        case (.quest, false): return "New quest: stand up and walk ten steps! Reward: ten more minutes of butt life!"
        case (.fart, true): return "不好！你的椅子快被坐出包浆啦！"
        case (.fart, false): return "Oh no! Your chair is getting a permanent butt print!"
        case (.duckling, true): return "你该起来动动了！再不动，我就叫全村的鸭子来啄你的键盘啦！"
        case (.duckling, false): return "Time to get up and move! Or I'll call every duck in the village to peck your keyboard!"
        case (.grandpa, true): return "哎哟……年轻人，屁股，要，长，蘑菇，了……快起来走走吧。"
        case (.grandpa, false): return "Oh dear... young one, your butt... is growing... mushrooms. Up you get, take a walk."
        case (.sitAlarm, true): return "警报警报！久坐超标！请立刻起立，原地转三圈！重复一遍，立刻起立！"
        case (.sitAlarm, false): return "Alert! Alert! Sitting limit exceeded! Stand up and spin three times! Repeat, stand up now!"
        case (.cuddly, true): return "主人～起来陪我走两步嘛～就两步，好不好嘛～"
        case (.cuddly, false): return "Pleeease get up and walk with me~ just two steps, pretty please~"
        case (.commentator, true): return "各位观众！这位选手已经连续坐了\(minutes)分钟，打破了今日纪录！让我们请他起立，为他的屁股鼓掌！"
        case (.commentator, false): return "Ladies and gentlemen! This player has been sitting for \(minutes) minutes straight, a new record! Let's have him stand up for a round of applause!"
        }
    }

    public var intro: [Double] {
        var s = Synth()
        switch self {
        case .duck: return s.cat(s.quack(), s.silence(0.12), s.quack(0.17, 520, 300))
        case .buttAlarm: return s.siren()
        case .cat: return s.meow()
        case .ghost: return s.ghostBoo()
        case .frog: return s.croak()
        case .emperor: return s.fanfare()
        case .rogueAI: return s.glitch()
        case .rooster: return s.rooster()
        case .quest: return s.ding()
        case .fart: return s.fart()
        case .duckling: return s.cat(s.quack(), s.silence(0.06), s.quack(0.17, 520, 300))
        case .grandpa: return s.cat(s.quack(0.6, 520, 240), s.silence(0.15), s.caneTaps())
        case .sitAlarm: return s.cat(s.quack(0.1), s.silence(0.03), s.quack(0.1), s.silence(0.03), s.quack(0.12, 600, 300), s.silence(0.1), s.siren())
        case .cuddly: return s.cat(s.squeak(), s.silence(0.08), s.squeak())
        case .commentator: return s.cat(s.quack(), s.silence(0.1), s.cheer())
        }
    }

    public var outro: [Double] {
        var s = Synth()
        switch self {
        case .duck: return s.duckLaugh()
        case .buttAlarm: return s.boing()
        case .cat: return s.hiss()
        case .ghost: return s.ghostGiggle()
        case .frog: return s.springJump()
        case .emperor: return s.gong()
        case .rogueAI: return s.errorTone()
        case .rooster: return s.flap()
        case .quest: return s.levelUp()
        case .fart: return s.slideDown()
        case .duckling: return s.flap()
        case .grandpa: return s.mushroomPops()
        case .sitAlarm: return s.allClear()
        case .cuddly: return s.kissChime()
        case .commentator: return s.applause()
        }
    }

    public var introWAV: Data { WAV.encode(Synth.normalised(intro, peak: 0.7), sampleRate: Synth.sampleRate) }
    public var outroWAV: Data { WAV.encode(Synth.normalised(outro, peak: 0.7), sampleRate: Synth.sampleRate) }
}

public enum WAV {
    /// 16-bit mono RIFF/WAVE, ready for NSSound(data:).
    public static func encode(_ samples: [Double], sampleRate: Int) -> Data {
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        for s in samples { append(Int16(max(-1, min(1, s)) * Double(Int16.max))) }
        return data
    }
}

/// The small kit of oscillators, filters and envelopes the skits are made from.
struct Synth {
    static let sampleRate = 22_050
    private let sr = Double(Synth.sampleRate)
    private var seed: UInt64 = 0x2545_F491_4F6C_DD1D

    enum Shape { case sine, square, saw, pulse }

    static func normalised(_ x: [Double], peak: Double) -> [Double] {
        let m = x.map(abs).max() ?? 0
        return m > 0 ? x.map { $0 / m * peak } : x
    }

    private mutating func random() -> Double {
        seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(seed >> 11) / Double(1 << 53)
    }

    func silence(_ seconds: Double) -> [Double] { Array(repeating: 0, count: Int(seconds * sr)) }

    func cat(_ parts: [Double]...) -> [Double] { parts.flatMap { $0 } }

    private func envelope(_ i: Int, _ n: Int, attack: Double, decay: Double) -> Double {
        let t = Double(i) / sr
        return min(1, t / attack) * pow(max(0, 1 - Double(i) / Double(n)), decay)
    }

    func osc(
        _ seconds: Double, _ shape: Shape, attack: Double = 0.01, decay: Double = 1.2,
        frequency: (Double, Double) -> Double
    ) -> [Double] {
        let n = Int(seconds * sr)
        var phase = 0.0
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / sr
            phase += frequency(t, Double(i) / Double(n)) / sr
            phase -= floor(phase)
            let v: Double
            switch shape {
            case .sine: v = sin(2 * .pi * phase)
            case .square: v = phase < 0.5 ? 1 : -1
            case .saw: v = 2 * phase - 1
            case .pulse: v = phase < 0.22 ? 1 : -0.28
            }
            out[i] = v * envelope(i, n, attack: attack, decay: decay)
        }
        return out
    }

    mutating func noise(_ seconds: Double, attack: Double = 0.005, decay: Double = 1) -> [Double] {
        let n = Int(seconds * sr)
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n { out[i] = (random() * 2 - 1) * envelope(i, n, attack: attack, decay: decay) }
        return out
    }

    func formant(_ x: [Double], _ bands: [(Double, Double, Double)]) -> [Double] {
        var filters = bands.map { Resonator(frequency: $0.0, q: $0.1, sampleRate: sr) }
        return x.map { v in
            var sum = 0.0
            for k in filters.indices { sum += bands[k].2 * filters[k].process(v) }
            return sum
        }
    }

    mutating func roughen(_ x: [Double], _ amount: Double) -> [Double] {
        x.map { $0 + (random() - 0.5) * amount }
    }

    // MARK: the sounds

    mutating func quack(_ length: Double = 0.17, _ f1: Double = 560, _ f2: Double = 330) -> [Double] {
        let src = osc(length, .pulse, attack: 0.008, decay: 1.6) { _, p in f1 * pow(f2 / f1, p) }
        return formant(roughen(src, 0.2), [(1_050, 4, 1), (2_600, 6, 0.55)])
    }

    mutating func duckLaugh() -> [Double] {
        var out: [Double] = []
        for i in 0..<7 {
            out += quack(0.09, 620 - 20 * Double(i), 480 - 25 * Double(i))
            out += silence(0.035)
        }
        return out
    }

    func siren() -> [Double] {
        [960.0, 770, 960, 770].flatMap { f in osc(0.28, .square, decay: 0.2) { _, _ in f } }
    }

    func boing() -> [Double] {
        osc(0.7, .sine, attack: 0.005) { t, p in 220 + 380 * pow(1 - p, 2) + 40 * sin(2 * .pi * 14 * t) * (1 - p) }
    }

    func meow() -> [Double] {
        formant(osc(0.75, .saw, attack: 0.05, decay: 1) { _, p in 500 + 350 * sin(.pi * min(1, p * 1.3)) },
                [(900, 3, 1), (1_800, 5, 0.6)])
    }

    mutating func hiss() -> [Double] {
        formant(noise(0.8, attack: 0.05, decay: 1.5), [(4_500, 1.5, 1), (7_000, 2, 0.6)])
    }

    func ghostBoo() -> [Double] {
        cat(
            osc(1.1, .sine, attack: 0.15, decay: 0.6) { t, p in 330 + 60 * sin(2 * .pi * 5 * t) + 120 * p },
            silence(0.05),
            formant(osc(0.25, .saw, attack: 0.005, decay: 1.5) { _, p in 260 - 80 * p }, [(700, 4, 1), (1_200, 5, 0.5)])
        )
    }

    func ghostGiggle() -> [Double] {
        (0..<8).flatMap { i in
            osc(0.07, .sine, attack: 0.005, decay: 1) { _, p in 900 + 120 * Double(i) - 300 * p } + silence(0.04)
        }
    }

    mutating func croak() -> [Double] { cat(quack(0.2, 180, 140), silence(0.12), quack(0.22, 170, 130)) }

    func springJump() -> [Double] { osc(0.35, .sine, attack: 0.005, decay: 0.6) { _, p in 300 + 1_200 * pow(p, 1.5) } }

    func fanfare() -> [Double] {
        let notes: [(Double, Double)] = [(392, 0.14), (392, 0.14), (523, 0.5)]
        let brass: [(Double, Double, Double)] = [(1_200, 2, 1), (2_500, 3, 0.5)]
        var out: [Double] = []
        for (pitch, length) in notes {
            let tone = osc(length, .saw, attack: 0.02, decay: 0.4) { t, _ in
                let wobble: Double = 1 + 0.01 * sin(2 * Double.pi * 6 * t)
                return pitch * wobble
            }
            out += formant(tone, brass)
            out += silence(0.04)
        }
        return out
    }

    func gong() -> [Double] {
        let n = Int(1.4 * sr)
        return (0..<n).map { i in
            let t = Double(i) / sr
            let partials = [(196.0, 1.0), (392, 0.5), (523, 0.25), (740, 0.15)]
            return partials.reduce(0) { $0 + $1.1 * sin(2 * .pi * $1.0 * t) } * exp(-3 * t)
        }
    }

    mutating func glitch() -> [Double] {
        var out: [Double] = []
        let freqs = [150.0, 300, 1_200, 2_400, 80]
        for _ in 0..<9 {
            let f = freqs[Int(random() * Double(freqs.count))]
            let length = 0.03 + random() * 0.06
            let shape: Shape = random() < 0.5 ? .square : .saw
            out += osc(length, shape, attack: 0.002, decay: 0.2) { _, _ in f }.map { ($0 * 4).rounded() / 4 }
            out += silence(random() * 0.03)
        }
        return out
    }

    func errorTone() -> [Double] {
        cat(osc(0.22, .square, attack: 0.005, decay: 0.5) { _, _ in 440 }, silence(0.04),
            osc(0.4, .square, attack: 0.005, decay: 1.2) { _, _ in 311 })
    }

    func rooster() -> [Double] {
        func syllable(_ f: Double, _ length: Double) -> [Double] {
            formant(osc(length, .saw, attack: 0.02, decay: 0.8) { _, p in f * (1 + 0.25 * sin(.pi * p)) },
                    [(800, 4, 1), (1_400, 5, 0.6), (2_600, 6, 0.3)])
        }
        return cat(syllable(500, 0.22), silence(0.05), syllable(600, 0.22), silence(0.05), syllable(700, 0.65))
    }

    mutating func flap() -> [Double] {
        var out: [Double] = []
        for _ in 0..<8 { out += formant(noise(0.06, attack: 0.003, decay: 2), [(1_500, 1, 1)]) + silence(0.05) }
        return out
    }

    func ding() -> [Double] { osc(0.8, .sine, attack: 0.003, decay: 2.5) { _, _ in 1_760 } }

    func levelUp() -> [Double] {
        [523.0, 659, 784, 1_047].flatMap { f in osc(0.11, .square, attack: 0.005, decay: 0.5) { _, _ in f } }
            + osc(0.45, .square, attack: 0.005, decay: 1.5) { _, _ in 1_319 }
    }

    mutating func fart() -> [Double] {
        let src = osc(0.9, .pulse, attack: 0.02, decay: 0.7) { t, p in 95 + 30 * sin(2 * .pi * 9 * t) - 30 * p }
        return formant(roughen(src, 0.6), [(220, 2, 1), (500, 3, 0.5)])
    }

    func caneTaps() -> [Double] {
        let wood: [(Double, Double, Double)] = [(900, 6, 1), (1_800, 8, 0.4)]
        var out: [Double] = []
        for i in 0..<3 {
            let pitch: Double = 180 + 20 * Double(i)
            out += formant(osc(0.09, .sine, attack: 0.002, decay: 3) { _, _ in pitch }, wood)
            out += silence(0.22)
        }
        return out
    }

    func mushroomPops() -> [Double] {
        var out: [Double] = []
        for i in 0..<3 {
            let base: Double = 500 + 150 * Double(i)
            out += osc(0.12, .sine, attack: 0.002, decay: 2) { _, p in base * (1 + 1.5 * p) }
            out += silence(0.12)
        }
        return out
    }

    func allClear() -> [Double] {
        cat(osc(0.35, .sine, attack: 0.005, decay: 1.4) { _, _ in 1_319 },
            osc(0.6, .sine, attack: 0.005, decay: 1.6) { _, _ in 1_047 })
    }

    func squeak() -> [Double] {
        osc(0.22, .sine, attack: 0.01, decay: 0.8) { t, p in
            let rise: Double = 700 * sin(Double.pi * p)
            let wobble: Double = 60 * sin(2 * Double.pi * 28 * t)
            return 1_700 + rise + wobble
        }
    }

    func kissChime() -> [Double] {
        var out = osc(0.08, .sine, attack: 0.002, decay: 1.5) { _, p in 1_200 + 1_400 * p }
        out += silence(0.05)
        for f in [2_093.0, 2_637, 3_136] {
            out += osc(0.18, .sine, attack: 0.003, decay: 2) { _, _ in f }
        }
        return out
    }

    /// Many short noise claps scattered in time, the way a crowd sounds.
    mutating func applause(_ seconds: Double = 1.8) -> [Double] {
        let n = Int(seconds * sr)
        var out = [Double](repeating: 0, count: n)
        for _ in 0..<Int(seconds * 60) {
            let start = Int(random() * Double(n - 2_000))
            let clap = formant(noise(0.025, attack: 0.001, decay: 3), [(1_200 + random() * 1_500, 1.2, 1)])
            let fade = 1 - Double(start) / Double(n)
            for (k, v) in clap.enumerated() where start + k < n { out[start + k] += v * (0.4 + 0.6 * fade) }
        }
        return out
    }

    mutating func cheer() -> [Double] {
        let crowd = formant(noise(1.1, attack: 0.2, decay: 0.8), [(600, 2, 1), (1_100, 3, 0.6)])
        let whoo = osc(1.1, .saw, attack: 0.2, decay: 0.8) { t, p in
            let vibrato: Double = 15 * sin(2 * Double.pi * 6 * t)
            return 380 + 160 * p + vibrato
        }
        let voices = formant(whoo, [(750, 5, 1), (1_200, 6, 0.5)])
        return zip(crowd, voices).map { $0 * 0.6 + $1 * 0.4 }
    }

    func slideDown() -> [Double] { osc(0.9, .sine, attack: 0.01, decay: 0.4) { _, p in 1_500 * pow(300 / 1_500, p) } }
}

/// A two-pole band-pass filter, the textbook biquad.
struct Resonator {
    private let b0, b2, a1, a2: Double
    private var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    init(frequency: Double, q: Double, sampleRate: Double) {
        let w = 2 * Double.pi * frequency / sampleRate
        let alpha = sin(w) / (2 * q)
        let a0 = 1 + alpha
        b0 = alpha / a0
        b2 = -alpha / a0
        a1 = -2 * cos(w) / a0
        a2 = (1 - alpha) / a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x; y2 = y1; y1 = y
        return y
    }
}

extension ReminderSkit {
    /// The emperor, the rogue AI, the rooster and the frog want a man's voice; the rest are
    /// fine with whatever is clearest.
    /// How the line is read, as multipliers on the voice's normal pitch and speed. Kept within
    /// fifteen percent so every word stays clear.
    public var delivery: (pitch: Double, rate: Double) {
        switch self {
        case .grandpa: return (0.88, 0.85)
        case .sitAlarm: return (1.05, 1.15)
        case .cuddly, .cat, .ghost: return (1.12, 1.0)
        case .commentator, .emperor: return (0.95, 0.95)
        case .duckling: return (1.1, 1.05)
        default: return (1, 1)
        }
    }

    public var prefersMaleVoice: Bool {
        switch self {
        case .emperor, .rogueAI, .rooster, .frog, .grandpa, .commentator: return true
        default: return false
        }
    }
}

/// A shuffle bag: every skit plays once before any repeats, and a new round never starts
/// with the one that ended the last.
public struct SkitBag: Codable, Sendable, Hashable {
    public private(set) var remaining: [Int]
    public private(set) var last: Int?

    public init(remaining: [Int] = [], last: Int? = nil) {
        self.remaining = remaining.filter { ReminderSkit(rawValue: $0) != nil }
        self.last = last
    }

    public mutating func draw(shuffle: ([Int]) -> [Int] = { $0.shuffled() }) -> ReminderSkit {
        if remaining.isEmpty {
            var round = shuffle(ReminderSkit.allCases.map(\.rawValue))
            if round.first == last, round.count > 1 { round.swapAt(0, round.count - 1) }
            remaining = round
        }
        let raw = remaining.removeFirst()
        last = raw
        return ReminderSkit(rawValue: raw) ?? .duck
    }
}
