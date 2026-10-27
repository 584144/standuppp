import AppKit
import SitlessCore
import SwiftUI

/// A small round companion that floats over the desktop and shows, by its face, how long
/// you have been sitting. It never takes focus, stays out of screen recordings and shares,
/// and only its own shape catches the mouse.
@MainActor
final class DesktopPetController {
    private static let size = NSSize(width: 230, height: 160)
    private static let originKey = "desktopPetOrigin"

    private let model: AppModel
    private var panel: NSPanel?

    init(model: AppModel) {
        self.model = model
    }

    func apply() {
        if model.settings.showDesktopPet { show() } else { hide() }
    }

    func setVisible(_ visible: Bool) {
        var updated = model.settings
        updated.showDesktopPet = visible
        model.update(settings: updated)
    }

    private func show() {
        if let panel {
            panel.orderFrontRegardless()
            return
        }
        let panel = PetPanel(
            contentRect: NSRect(origin: Self.savedOrigin() ?? Self.defaultOrigin(), size: Self.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.sharingType = .none
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        let host = PetHostingView(
            rootView: DesktopPetView(
                model: model,
                move: { [weak panel] delta in
                    guard let panel else { return }
                    var origin = panel.frame.origin
                    origin.x += delta.width
                    origin.y -= delta.height
                    panel.setFrameOrigin(origin)
                },
                moved: { [weak panel] in
                    guard let panel else { return }
                    UserDefaults.standard.set(NSStringFromPoint(panel.frame.origin), forKey: Self.originKey)
                },
                hide: { [weak self] in self?.setVisible(false) }
            )
        )
        host.frame = NSRect(origin: .zero, size: Self.size)
        panel.contentView = host
        panel.orderFrontRegardless()
        self.panel = panel
    }

    private func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private static func savedOrigin() -> NSPoint? {
        guard let raw = UserDefaults.standard.string(forKey: originKey) else { return nil }
        let point = NSPointFromString(raw)
        let onScreen = NSScreen.screens.contains { $0.visibleFrame.insetBy(dx: -40, dy: -40).contains(point) }
        return onScreen ? point : nil
    }

    private static func defaultOrigin() -> NSPoint {
        let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSPoint(x: frame.maxX - size.width - 24, y: frame.minY + 24)
    }
}

private final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class PetHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

struct DesktopPetView: View {
    let model: AppModel
    let move: (CGSize) -> Void
    let moved: () -> Void
    let hide: () -> Void

    @State private var showingInfo = false
    @State private var lastDrag: CGSize = .zero
    @State private var dragging = false
    @State private var spunAt: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func mood(at now: Date) -> PetMood {
        PetMood.mood(
            indicator: model.indicator,
            workFraction: model.workTarget > 0 ? model.displayedContinuousWork / model.workTarget : 0,
            lastBreak: model.lastBreak,
            now: now
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: reduceMotion)) { context in
            let now = context.date
            let mood = mood(at: now)
            let t = now.timeIntervalSinceReferenceDate
            VStack(spacing: 4) {
                bubble(for: mood)
                    .frame(height: 44, alignment: .bottom)
                PetFace(
                    mood: mood, time: reduceMotion ? 0 : t,
                    tilt: reduceMotion ? 0 : cursorTilt(),
                    spin: reduceMotion ? 0 : spin(at: now),
                    wiggle: dragging && !reduceMotion
                )
                    .frame(width: 96, height: 96)
                    .offset(y: reduceMotion ? 0 : Self.bob(mood, t))
                    .contentShape(Circle())
                    .gesture(drag)
                    .onTapGesture(count: 2) { model.takeBreakNow() }
                    .onTapGesture {
                        showingInfo.toggle()
                        spunAt = .now
                    }
                    .contextMenu {
                        Button(L("Take a break now")) { model.takeBreakNow() }
                        Button(L("Hide the pet")) { hide() }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(L(Self.spoken(mood)))
            }
            .frame(width: 230, height: 160, alignment: .bottom)
        }
    }

    /// Leans a little toward the pointer when it comes close, like it is having a look.
    private func cursorTilt() -> Double {
        guard let window = NSApp.windows.first(where: { $0 is NSPanel && $0.contentView is NSHostingView<DesktopPetView> })
        else { return 0 }
        let center = NSPoint(x: window.frame.midX, y: window.frame.minY + 50)
        let cursor = NSEvent.mouseLocation
        let dx = cursor.x - center.x, dy = cursor.y - center.y
        guard dx * dx + dy * dy < 260 * 260 else { return 0 }
        return max(-1, min(1, dx / 200)) * 12
    }

    /// One full happy turn after a click.
    private func spin(at now: Date) -> Double {
        guard let spunAt else { return 0 }
        let p = now.timeIntervalSince(spunAt) / 0.7
        guard p < 1 else { return 0 }
        return (1 - pow(1 - p, 3)) * 360
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                dragging = true
                let delta = CGSize(
                    width: value.translation.width - lastDrag.width,
                    height: value.translation.height - lastDrag.height
                )
                lastDrag = value.translation
                move(delta)
            }
            .onEnded { _ in
                dragging = false
                lastDrag = .zero
                moved()
            }
    }

    @ViewBuilder
    private func bubble(for mood: PetMood) -> some View {
        if showingInfo {
            SpeechBubble(text: infoLine)
                .onTapGesture { showingInfo = false }
        } else if let line = Self.line(for: mood) {
            SpeechBubble(text: L(line))
        }
    }

    private var infoLine: String {
        let sat = DurationText.short(model.displayedContinuousWork)
        let breaks = model.todaySummary?.breakCount ?? 0
        let left = max(0, model.workTarget - model.displayedContinuousWork)
        if Localizer.chinese {
            return "已连续坐 \(sat) · 今天休息 \(breaks) 次\n再过 \(DurationText.short(left)) 该起来了"
        }
        return "Sitting \(sat) · \(breaks) breaks today\nUp again in \(DurationText.short(left))"
    }

    static func line(for mood: PetMood) -> String? {
        switch mood {
        case .nudging: return "Time to stand up!"
        case .resting: return nil
        case .proud: return "Nice break!"
        case .sulking: return "That break didn't count…"
        case .tired: return "Getting stiff…"
        case .fresh, .focused, .away: return nil
        }
    }

    static func spoken(_ mood: PetMood) -> String {
        switch mood {
        case .fresh: return "Pet, fresh"
        case .focused: return "Pet, focused"
        case .tired: return "Pet, tired"
        case .nudging: return "Pet, asking you to stand up"
        case .resting: return "Pet, asleep"
        case .proud: return "Pet, proud of your break"
        case .sulking: return "Pet, sulking"
        case .away: return "Pet, waiting"
        }
    }

    static func bob(_ mood: PetMood, _ t: Double) -> CGFloat {
        switch mood {
        case .nudging: return -abs(sin(t * 5)) * 14
        case .proud: return -abs(sin(t * 4)) * 8
        case .fresh: return sin(t * 2) * 3
        case .focused: return sin(t * 1.4) * 2
        case .tired, .sulking: return sin(t * 0.8) * 1.5
        case .resting, .away: return 0
        }
    }
}

struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(white: 0.12))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
            )
            .fixedSize()
    }
}

/// A soft white mochi ghost. Its mood decides the eyes, the mouth, what it holds (a laptop
/// while you work, a pillow while you rest) and the little things floating around it.
struct PetFace: View {
    let mood: PetMood
    let time: Double
    /// Degrees to lean toward the cursor.
    var tilt: Double = 0
    /// Degrees of a celebratory spin in progress.
    var spin: Double = 0
    /// True while it is being dragged: the arms flap.
    var wiggle: Bool = false

    static let pearl = Color(.sRGB, red: 1.0, green: 0.99, blue: 1.0)
    static let lilac = Color(.sRGB, red: 0.88, green: 0.84, blue: 0.98)
    static let shade = Color(.sRGB, red: 0.76, green: 0.70, blue: 0.93)
    static let ink = Color(.sRGB, red: 0.10, green: 0.09, blue: 0.13)
    static let blush = Color(.sRGB, red: 1.0, green: 0.62, blue: 0.72)
    static let pink = Color(.sRGB, red: 1.0, green: 0.50, blue: 0.66)

    private var blinking: Bool {
        guard time > 0 else { return false }
        return time.truncatingRemainder(dividingBy: 4.2) < 0.13
    }

    private var working: Bool { mood == .focused || mood == .tired }

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                accents(s)
                ghost(s)
                    .rotationEffect(.degrees(tilt + leanForMood), anchor: .bottom)
                    .rotation3DEffect(.degrees(spin), axis: (x: 0, y: 1, z: 0))
                if working { laptop(s) }
                if mood == .resting { pillow(s) }
            }
            .frame(width: s, height: s)
        }
    }

    private var leanForMood: Double {
        switch mood {
        case .sulking: return -10
        case .tired: return 4
        default: return 0
        }
    }

    // MARK: body

    private func ghost(_ s: CGFloat) -> some View {
        ZStack {
            GhostShape()
                .fill(Self.shade.opacity(0.35))
                .blur(radius: s * 0.05)
                .offset(y: s * 0.04)
            GhostShape()
                .fill(
                    RadialGradient(
                        colors: [Self.pearl, Self.pearl, Self.lilac, Self.shade.opacity(0.9)],
                        center: UnitPoint(x: 0.38, y: 0.3), startRadius: 0, endRadius: s * 0.62
                    )
                )
                .overlay(
                    GhostShape()
                        .stroke(Color.white.opacity(0.7), lineWidth: s * 0.01)
                        .blur(radius: 0.6)
                )
            Ellipse()
                .fill(Color.white.opacity(0.9))
                .frame(width: s * 0.16, height: s * 0.09)
                .rotationEffect(.degrees(-25))
                .blur(radius: s * 0.012)
                .offset(x: -s * 0.17, y: -s * 0.24)
            arms(s)
            face(s)
                .offset(y: -s * 0.04)
            if mood == .tired || mood == .sulking { sweat(s) }
        }
        .frame(width: s * 0.72, height: s * 0.8)
        .saturation(mood == .away ? 0.7 : 1)
    }

    private func arms(_ s: CGFloat) -> some View {
        let flap = wiggle ? sin(time * 18) * 22 : 0
        let wave = mood == .nudging ? sin(time * 7) * 35 - 30 : 0
        return ZStack {
            arm(s)
                .rotationEffect(.degrees(25 + flap), anchor: .trailing)
                .offset(x: -s * 0.37, y: s * 0.06)
            arm(s)
                .rotationEffect(.degrees(-25 - flap + wave), anchor: .leading)
                .offset(x: s * 0.37, y: mood == .nudging ? -s * 0.02 : s * 0.06)
        }
    }

    private func arm(_ s: CGFloat) -> some View {
        Ellipse()
            .fill(LinearGradient(colors: [Self.pearl, Self.lilac], startPoint: .top, endPoint: .bottom))
            .frame(width: s * 0.13, height: s * 0.09)
            .shadow(color: Self.shade.opacity(0.4), radius: 1, y: 1)
    }

    // MARK: face

    private func face(_ s: CGFloat) -> some View {
        ZStack {
            HStack(spacing: s * 0.15) {
                eye(s, left: true)
                eye(s, left: false)
            }
            .offset(y: -s * 0.02)
            if working { glasses(s).offset(y: -s * 0.02) }
            HStack(spacing: s * 0.3) {
                Ellipse().fill(Self.blush.opacity(blushOpacity))
                Ellipse().fill(Self.blush.opacity(blushOpacity))
            }
            .frame(width: s * 0.46, height: s * 0.05)
            .blur(radius: s * 0.008)
            .offset(y: s * 0.065)
            mouth(s).offset(y: s * 0.07)
        }
    }

    private var blushOpacity: Double {
        switch mood {
        case .tired, .away: return 0.35
        case .sulking: return 0.45
        default: return 0.8
        }
    }

    @ViewBuilder
    private func eye(_ s: CGFloat, left: Bool) -> some View {
        let w = s * 0.075, h = s * 0.105
        switch mood {
        case .resting:
            Arc(up: false).stroke(Self.ink, style: StrokeStyle(lineWidth: s * 0.022, lineCap: .round))
                .frame(width: w * 1.1, height: h * 0.35)
        case .proud, .fresh where left == false && time.truncatingRemainder(dividingBy: 6) > 5:
            Arc(up: true).stroke(Self.ink, style: StrokeStyle(lineWidth: s * 0.024, lineCap: .round))
                .frame(width: w * 1.1, height: h * 0.4)
        case .away where left == false:
            Arc(up: true).stroke(Self.ink, style: StrokeStyle(lineWidth: s * 0.022, lineCap: .round))
                .frame(width: w * 1.1, height: h * 0.35)
        default:
            let tiredSquash: CGFloat = mood == .tired ? 0.6 : 1
            ZStack(alignment: .topTrailing) {
                Ellipse().fill(Self.ink)
                Circle().fill(Color.white).frame(width: w * 0.42).offset(x: -w * 0.12, y: h * 0.1)
            }
            .frame(width: w, height: blinking ? h * 0.12 : h * tiredSquash)
        }
    }

    private func glasses(_ s: CGFloat) -> some View {
        HStack(spacing: s * 0.035) {
            Circle().stroke(Self.ink, lineWidth: s * 0.016).frame(width: s * 0.15)
            Circle().stroke(Self.ink, lineWidth: s * 0.016).frame(width: s * 0.15)
        }
        .overlay(Rectangle().fill(Self.ink).frame(width: s * 0.04, height: s * 0.014))
    }

    @ViewBuilder
    private func mouth(_ s: CGFloat) -> some View {
        switch mood {
        case .proud, .fresh, .nudging:
            ZStack(alignment: .top) {
                HalfDisc().fill(Self.ink).frame(width: s * 0.075, height: s * 0.045)
                Ellipse().fill(Self.pink).frame(width: s * 0.04, height: s * 0.022).offset(y: s * 0.022)
            }
            .clipShape(HalfDisc().size(width: s * 0.075, height: s * 0.045))
            .frame(width: s * 0.075, height: s * 0.045)
        case .sulking:
            Arc(up: true).stroke(Self.ink, style: StrokeStyle(lineWidth: s * 0.016, lineCap: .round))
                .frame(width: s * 0.05, height: s * 0.016)
        case .tired:
            Capsule().fill(Self.ink).frame(width: s * 0.04, height: s * 0.014)
        case .focused, .resting, .away:
            Arc(up: false).stroke(Self.ink, style: StrokeStyle(lineWidth: s * 0.016, lineCap: .round))
                .frame(width: s * 0.05, height: s * 0.018)
        }
    }

    private func sweat(_ s: CGFloat) -> some View {
        Drop()
            .fill(LinearGradient(
                colors: [Color(.sRGB, red: 0.75, green: 0.9, blue: 1), Color(.sRGB, red: 0.5, green: 0.75, blue: 1)],
                startPoint: .top, endPoint: .bottom))
            .frame(width: s * 0.05, height: s * 0.075)
            .offset(x: s * 0.24, y: -s * 0.16)
    }

    // MARK: props

    private func laptop(_ s: CGFloat) -> some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: s * 0.025, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(white: 0.93), Color(white: 0.76)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().fill(Color.white.opacity(0.8)).frame(width: s * 0.035))
                .frame(width: s * 0.42, height: s * 0.24)
            Capsule()
                .fill(Color(white: 0.7))
                .frame(width: s * 0.5, height: s * 0.035)
        }
        .shadow(color: Self.shade.opacity(0.5), radius: s * 0.02, y: s * 0.01)
        .offset(y: s * 0.28)
    }

    private func pillow(_ s: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: s * 0.1, style: .continuous)
            .fill(LinearGradient(
                colors: [Color(.sRGB, red: 0.86, green: 0.8, blue: 1), Color(.sRGB, red: 0.72, green: 0.64, blue: 0.95)],
                startPoint: .top, endPoint: .bottom))
            .frame(width: s * 0.46, height: s * 0.24)
            .overlay(
                HStack(spacing: s * 0.25) {
                    Ellipse().fill(Self.pearl).frame(width: s * 0.1, height: s * 0.07)
                    Ellipse().fill(Self.pearl).frame(width: s * 0.1, height: s * 0.07)
                }
                .offset(y: -s * 0.09)
            )
            .rotationEffect(.degrees(-6))
            .offset(y: s * 0.26)
    }

    // MARK: things floating around it

    @ViewBuilder
    private func accents(_ s: CGFloat) -> some View {
        let drift = sin(time * 2) * s * 0.02
        switch mood {
        case .fresh, .proud:
            Image(systemName: "heart.fill")
                .font(.system(size: s * 0.12))
                .foregroundStyle(Self.pink)
                .offset(x: s * 0.36, y: -s * 0.3 + drift)
            if mood == .proud {
                Image(systemName: "sparkle")
                    .font(.system(size: s * 0.1))
                    .foregroundStyle(Color(.sRGB, red: 1, green: 0.8, blue: 0.4))
                    .offset(x: -s * 0.38, y: -s * 0.22 - drift)
                Image(systemName: "sparkle")
                    .font(.system(size: s * 0.07))
                    .foregroundStyle(Self.shade)
                    .offset(x: -s * 0.3, y: s * 0.12 + drift)
            }
        case .nudging:
            Ticks().stroke(Self.shade, style: StrokeStyle(lineWidth: s * 0.018, lineCap: .round))
                .frame(width: s * 0.12, height: s * 0.12)
                .offset(x: s * 0.4, y: -s * 0.3)
        case .resting:
            Text("z z")
                .font(.system(size: s * 0.11, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.shade)
                .offset(x: s * 0.3, y: -s * 0.36 + drift)
        case .sulking:
            Text("?")
                .font(.system(size: s * 0.16, weight: .bold, design: .rounded))
                .foregroundStyle(Self.shade)
                .offset(x: -s * 0.34, y: -s * 0.36 + drift)
        case .focused, .tired, .away:
            EmptyView()
        }
    }
}

/// Round top, straight sides, three soft scallops along the bottom.
struct GhostShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let r = w / 2
        let bottom = rect.maxY - h * 0.06
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + r), radius: r,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: bottom - h * 0.06))
        let bumps = 3
        let step = w / CGFloat(bumps)
        for i in 0..<bumps {
            let x0 = rect.maxX - CGFloat(i) * step
            let x1 = x0 - step
            p.addQuadCurve(to: CGPoint(x: x1, y: bottom - h * 0.06),
                           control: CGPoint(x: (x0 + x1) / 2, y: bottom + h * 0.1))
        }
        p.closeSubpath()
        return p
    }
}

private struct Arc: Shape {
    let up: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: up ? rect.maxY : rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: up ? rect.maxY : rect.minY),
            control: CGPoint(x: rect.midX, y: up ? rect.minY - rect.height : rect.maxY + rect.height)
        )
        return p
    }
}

private struct HalfDisc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: rect.maxY * 2 - rect.minY))
        p.closeSubpath()
        return p
    }
}

private struct Drop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX + rect.width * 0.3, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX - rect.width * 0.3, y: rect.maxY))
        return p
    }
}

/// Three little motion strokes, as in "look over here".
private struct Ticks: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        for i in 0..<3 {
            let angle = Double(-60 + i * 30) * .pi / 180
            let a = CGPoint(x: rect.minX + rect.width * 0.2, y: rect.maxY - rect.height * 0.2)
            p.move(to: CGPoint(x: a.x + cos(angle) * rect.width * 0.35, y: a.y + sin(angle) * rect.height * 0.35))
            p.addLine(to: CGPoint(x: a.x + cos(angle) * rect.width * 0.75, y: a.y + sin(angle) * rect.height * 0.75))
        }
        return p
    }
}

/// `sitless --render-pet <stem>`: every mood side by side, for the README and for checking
/// a change to the face without waiting fifty minutes for it.
@MainActor
enum PetSheetRenderer {
    static func runAndExit(stem: String) -> Never {
        let sheet = HStack(alignment: .bottom, spacing: 18) {
            ForEach(PetMood.allCases, id: \.self) { mood in
                VStack(spacing: 6) {
                    if let line = DesktopPetView.line(for: mood) {
                        SpeechBubble(text: L(line))
                    }
                    PetFace(mood: mood, time: 1).frame(width: 84, height: 84)
                    Text(mood.rawValue).font(.system(size: 11, design: .monospaced)).foregroundStyle(.secondary)
                }
                .frame(width: 130, height: 170, alignment: .bottom)
            }
        }
        .padding(24)
        .background(Color(white: 0.93))
        let renderer = ImageRenderer(content: sheet)
        renderer.scale = 2
        let url = URL(fileURLWithPath: "\(stem).png")
        if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
            FileHandle.standardOutput.write(Data("\(url.path)\n".utf8))
            exit(0)
        }
        FileHandle.standardError.write(Data("render failed\n".utf8))
        exit(1)
    }
}
