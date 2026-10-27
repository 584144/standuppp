import Foundation

/// A cartoon duck's "quack", made from nothing but arithmetic so the app ships no recorded
/// audio: a buzzy pulse whose pitch drops fast, pushed through two vowel-like resonances and
/// shaped by a quick envelope. Two of them in a row, as a duck would.
public enum QuackSynth {
    public static let sampleRate = 22_050
    public static let quackLength = 0.17
    public static let gap = 0.06
    public static let count = 2

    public static var duration: TimeInterval {
        Double(count) * quackLength + Double(count - 1) * gap
    }

    /// 16-bit mono PCM samples in [-1, 1] before quantising.
    public static func samples() -> [Double] {
        var out: [Double] = []
        let gapSamples = Int(gap * Double(sampleRate))
        for i in 0..<count {
            out += quack(pitchScale: i == 0 ? 1.0 : 0.92)
            if i < count - 1 { out += Array(repeating: 0, count: gapSamples) }
        }
        let peak = out.map(abs).max() ?? 1
        return peak > 0 ? out.map { $0 / peak * 0.8 } : out
    }

    private static func quack(pitchScale: Double) -> [Double] {
        let n = Int(quackLength * Double(sampleRate))
        let sr = Double(sampleRate)
        var phase = 0.0
        var low = Resonator(frequency: 1_050, q: 4, sampleRate: sr)
        var high = Resonator(frequency: 2_600, q: 6, sampleRate: sr)
        var seed: UInt64 = 0x9E37_79B9_7F4A_7C15
        var out = [Double](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / sr
            let p = t / quackLength
            let f0 = (560 * pow(330.0 / 560.0, p)) * pitchScale
            phase += f0 / sr
            phase -= floor(phase)
            // A narrow pulse is what makes it nasal rather than a whistle.
            let pulse = phase < 0.22 ? 1.0 : -0.28
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = (Double(seed >> 33) / Double(1 << 31) - 0.5) * 0.25
            let source = pulse + noise
            let shaped = low.process(source) * 1.0 + high.process(source) * 0.55 + source * 0.08
            let attack = min(1, t / 0.008)
            let decay = pow(max(0, 1 - p), 1.6)
            out[i] = shaped * attack * decay
        }
        return out
    }

    /// A RIFF/WAVE file of the quack, ready for NSSound(data:).
    public static func wav() -> Data {
        let pcm = samples().map { Int16(max(-1, min(1, $0)) * Double(Int16.max)) }
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(pcm.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + byteCount)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        for s in pcm { append(s) }
        return data
    }
}

/// A two-pole band-pass filter, the textbook biquad.
private struct Resonator {
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
