import AppKit
import StandupppCore
import SwiftUI

enum Brand {

    static let bg = dynamic(light: 0xFBFBF9, dark: 0x101317)
    static let bgRaised = dynamic(light: 0xFFFFFF, dark: 0x171A1F)
    static let surface = dynamic(light: 0xF4F4F1, dark: 0x1D2127)
    static let surfaceHi = dynamic(light: 0xE9E9E4, dark: 0x262B32)
    static let line = dynamic(light: 0xE7E7E1, dark: 0x2B313A)
    static let lineHi = dynamic(light: 0xCFCFC7, dark: 0x3A424D)

    static let fg = dynamic(light: 0x17191C, dark: 0xE8EAED)
    static let fgMuted = dynamic(light: 0x53585E, dark: 0x9AA2AD)

    static let fgFaint = dynamic(light: 0x6B7177, dark: 0x808894)

    static let chrome = dynamic(light: 0xF4F4F1, dark: 0x101317)

    static let content = dynamic(light: 0xFBFBF9, dark: 0x171A1F)

    static let running = dynamic(light: 0x15803D, dark: 0x3FB950)

    static let amber = dynamic(light: 0x0F6E57, dark: 0x55CDA6)

    static let amberFill = dynamic(light: 0x1FA67F, dark: 0x55CDA6)
    static let amberWash = dynamic(light: 0xE3F3EC, dark: 0x16221E)
    static let onAmber = dynamic(light: 0x1B1206, dark: 0x000000)

    static let alert = dynamic(light: 0xC0322B, dark: 0xF85149)

    enum Dark {
        static let bg = fixed(0x101317)
        static let fg = fixed(0xE8EAED)
        static let fgMuted = fixed(0x9AA2AD)
        static let line = fixed(0x2D343D)
        static let amber = fixed(0x55CDA6)
        static let onAmber = fixed(0x000000)
    }

    static func mono(_ size: CGFloat, weight: NSFont.Weight = .regular) -> Font {
        if let font = NSFont(name: "JetBrainsMono-\(jetBrainsStyle(for: weight))", size: size) {
            return Font(font)
        }
        return Font(NSFont.monospacedSystemFont(ofSize: size, weight: weight))
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    private static func jetBrainsStyle(for weight: NSFont.Weight) -> String {
        switch weight {
        case ..<NSFont.Weight.light: return "ExtraLight"
        case ..<NSFont.Weight.regular: return "Light"
        case ..<NSFont.Weight.medium: return "Regular"
        case ..<NSFont.Weight.semibold: return "Medium"
        case ..<NSFont.Weight.bold: return "SemiBold"
        default: return "Bold"
        }
    }

    @MainActor
    static func apply(_ preference: AppearancePreference, pinning statusButton: NSStatusBarButton?) {
        switch preference {
        case .system:
            NSApp.appearance = nil
            statusButton?.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
            statusButton?.appearance = systemAppearance()
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
            statusButton?.appearance = systemAppearance()
        }
    }

    static func systemAppearance() -> NSAppearance? {
        let dark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
        return NSAppearance(named: dark ? .darkAqua : .aqua)
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return nsColor(isDark ? dark : light)
        })
    }

    private static func fixed(_ hex: UInt32) -> Color {
        Color(nsColor: nsColor(hex))
    }

    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

struct BrandMark: View {
    var size: CGFloat = 40
    var fill: Double = 0.5
    var resting: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Brand.amber.opacity(0.3), lineWidth: max(1.5, size * 0.08))
            if resting {
                Capsule(style: .continuous)
                    .fill(Brand.amber)
                    .frame(width: size * 0.5, height: max(2, size * 0.1))
            } else {
                Circle()
                    .trim(from: 0, to: min(1, max(0, fill)))
                    .stroke(Brand.amber, style: StrokeStyle(lineWidth: max(2, size * 0.14), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(Brand.amberFill)
                    .frame(width: size * 0.2, height: size * 0.2)
            }
        }
        .padding(size * 0.08)
        .frame(width: size, height: size)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: fill)
        .accessibilityHidden(true)
    }
}

struct Kicker: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(L(text))
            .font(Brand.mono(10, weight: .medium))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Brand.fgMuted)
    }
}

struct StateDot: View {
    enum State { case running, suspend, alert, off }
    let state: State
    var size: CGFloat = 6

    var body: some View {
        Circle()
            .fill(colour)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private var colour: Color {
        switch state {
        case .running: return Brand.running
        case .suspend: return Brand.amber
        case .alert: return Brand.alert
        case .off: return Brand.fgFaint.opacity(0.6)
        }
    }
}

struct Rule: View {
    var body: some View {
        Rectangle()
            .fill(Brand.line)
            .frame(height: 1)
    }
}

struct TerminalButton: View {
    enum Style { case filled, outlined, quiet }

    static let quietInset: CGFloat = 8

    static let markInset: CGFloat = 12
    static let markGutter: CGFloat = 15

    let title: String
    var style: Style = .outlined
    var mark: String? = nil
    var enabled: Bool = true
    let action: () -> Void

    @FocusState private var focused: Bool
    @State private var keyboardFocused = false

    init(
        _ title: String,
        style: Style = .outlined,
        mark: String? = nil,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.mark = mark
        self.enabled = enabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(L(title))
                .font(Brand.mono(11, weight: style.weight))
        }
        .buttonStyle(
            TerminalButtonStyle(style: style, mark: mark, enabled: enabled, focused: focused && keyboardFocused)
        )
        .opacity(enabled ? 1 : 0.45)
        .disabled(!enabled)
        .focusable(enabled)
        .focusEffectDisabled()
        .focused($focused)
        .onChange(of: focused) { _, isFocused in
            keyboardFocused = isFocused && NSApp.currentEvent?.type == .keyDown
        }
    }
}

extension TerminalButton.Style {

    var weight: NSFont.Weight {
        switch self {
        case .filled: return .semibold
        case .outlined: return .medium
        case .quiet: return .regular
        }
    }

    var boxed: Bool { self != .quiet }
}

private struct TerminalButtonStyle: ButtonStyle {
    let style: TerminalButton.Style
    let mark: String?
    let enabled: Bool
    let focused: Bool

    func makeBody(configuration: Configuration) -> some View {
        Face(
            configuration: configuration,
            style: style,
            mark: mark,
            enabled: enabled,
            focused: focused
        )
    }

    private struct Face: View {
        let configuration: TerminalButtonStyle.Configuration
        let style: TerminalButton.Style
        let mark: String?
        let enabled: Bool
        let focused: Bool

        @State private var hovering = false

        private var shape: RoundedRectangle {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
        }

        private var pressed: Bool { configuration.isPressed && enabled }
        private var hot: Bool { hovering && enabled }

        var body: some View {
            content
                .padding(.horizontal, marked || style.boxed
                    ? TerminalButton.markInset
                    : TerminalButton.quietInset)
                .padding(.vertical, style.boxed ? 6 : 5)
                .frame(maxWidth: marked || style.boxed ? .infinity : nil, alignment: .leading)
                .contentShape(Rectangle())
                .foregroundStyle(foreground)
                .background(background, in: shape)
                .overlay(shape.strokeBorder(border, lineWidth: 1))
                .overlay(focusRing)
                .onHover { hovering = $0 }
        }

        private var marked: Bool { mark != nil }

        @ViewBuilder
        private var content: some View {
            if let mark {
                HStack(spacing: 0) {
                    Text(L(mark))
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(markInk)
                        .frame(width: TerminalButton.markGutter, alignment: .leading)
                        .accessibilityHidden(true)
                    configuration.label
                    Spacer(minLength: 0)
                }
            } else {
                configuration.label.frame(maxWidth: style.boxed ? .infinity : nil)
            }
        }

        private var markInk: Color {
            switch style {
            case .filled: return Brand.onAmber.opacity(0.55)
            case .outlined: return Brand.amber
            case .quiet: return Brand.fgMuted
            }
        }

        @ViewBuilder
        private var focusRing: some View {
            if focused, enabled {
                shape.inset(by: -2).strokeBorder(Brand.amber, lineWidth: 1.5)
            }
        }

        private var foreground: Color {
            switch style {
            case .filled: return Brand.onAmber
            case .outlined: return Brand.fg
            case .quiet:
                if marked { return Brand.fg }
                return hot || pressed ? Brand.fg : Brand.fgMuted
            }
        }

        private var background: Color {
            switch style {
            case .filled:
                if pressed { return Brand.amberFill.opacity(0.78) }
                return hot ? Brand.amberFill.opacity(0.88) : Brand.amberFill
            case .outlined:
                if pressed { return Brand.lineHi }
                return hot ? Brand.surfaceHi : Brand.surface
            case .quiet:
                if pressed { return Brand.lineHi }
                return hot ? Brand.surfaceHi : .clear
            }
        }

        private var border: Color {
            switch style {
            case .filled: return .clear
            case .outlined: return Brand.fgFaint
            case .quiet: return .clear
            }
        }
    }
}

struct TerminalSwitch: View {
    @Binding var isOn: Bool
    var enabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isOn ? Brand.amberFill : Brand.surfaceHi)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(isOn ? Color.clear : Brand.lineHi, lineWidth: 1)
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isOn ? Brand.onAmber : Brand.fgFaint)
                    .frame(width: 12, height: 12)
                    .padding(3)
            }
            .frame(width: 34, height: 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: isOn)
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .accessibilityRepresentation {
            Toggle("", isOn: $isOn)
        }
    }
}

struct TerminalStepper: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1
    var unit: String = ""

    var body: some View {
        HStack(spacing: 0) {
            control("−", enabled: value - step >= range.lowerBound) {
                value = max(range.lowerBound, value - step)
            }
            Rectangle().fill(Brand.lineHi).frame(width: 1, height: 24)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(L("\(value)"))
                    .font(Brand.mono(13, weight: .semibold))
                    .foregroundStyle(Brand.fg)
                    .monospacedDigit()
                if !unit.isEmpty {
                    Text(L(unit))
                        .font(Brand.mono(10))
                        .foregroundStyle(Brand.fgMuted)
                }
            }
            .frame(minWidth: 62)
            .padding(.horizontal, 6)
            Rectangle().fill(Brand.lineHi).frame(width: 1, height: 24)
            control("+", enabled: value + step <= range.upperBound) {
                value = min(range.upperBound, value + step)
            }
        }
        .background(Brand.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Brand.lineHi, lineWidth: 1)
        )
        .accessibilityRepresentation {
            Stepper(value: $value, in: range, step: step) { Text(L("\(value) \(unit)")) }
        }
    }

    private func control(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(L(glyph))
                .font(Brand.mono(13, weight: .medium))
                .foregroundStyle(enabled ? Brand.fg : Brand.fgFaint.opacity(0.5))
                .frame(width: 26, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct TerminalSegmented<Value: Hashable>: View {
    @Binding var selection: Value
    let options: [(value: Value, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                if index > 0 {
                    Rectangle().fill(Brand.lineHi).frame(width: 1, height: 24)
                }
                cell(option.value, option.label)
            }
        }
        .background(Brand.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Brand.lineHi, lineWidth: 1)
        )
    }

    private func cell(_ value: Value, _ label: String) -> some View {
        let on = value == selection
        return Button { selection = value } label: {
            Text(L(label))
                .font(Brand.mono(12, weight: on ? .semibold : .regular))
                .foregroundStyle(on ? Brand.fg : Brand.fgMuted)
                .frame(minWidth: 58)
                .frame(height: 24)
                .background(on ? Brand.surfaceHi : Color.clear)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
    }
}

struct TransferBar: View {
    let fraction: Double?
    var animated: Bool = true
    var tint: Color = Brand.amberFill
    var track: Color = Brand.surfaceHi
    var height: CGFloat = 3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                if let fraction {
                    Rectangle()
                        .fill(tint)
                        .frame(width: geometry.size.width * min(1, max(0, fraction)))
                        .animation(reduceMotion || !animated ? nil : .easeOut(duration: 0.4), value: fraction)
                } else if reduceMotion {
                    Rectangle().fill(tint.opacity(0.45))
                } else {
                    Rectangle()
                        .fill(tint)
                        .frame(width: geometry.size.width * 0.3)
                        .offset(x: sweep ? geometry.size.width * 0.7 : 0)
                        .animation(
                            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                            value: sweep
                        )
                        .onAppear { sweep = true }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: height / 2, style: .continuous))
    }
}
