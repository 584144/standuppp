import AppKit
import StandupppCore
import SwiftUI

/// The pictures the README and the app bundle use, drawn from the same views the app shows,
/// so the logo, the icon and the guide never drift from the real duck.
///
///   standuppp --render-logo <stem>      logo-light.png and logo-dark.png
///   standuppp --render-appicon <dir>    an .iconset folder for iconutil
///   standuppp --render-guide <stem>     the how-it-works picture for the README
@MainActor
enum BrandArt {
    static func write(_ view: some View, to path: String, scale: CGFloat = 2) -> Bool {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.nsImage, let tiff = image.tiffRepresentation,
              let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
        else { return false }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            FileHandle.standardOutput.write(Data("\(path)\n".utf8))
            return true
        } catch {
            return false
        }
    }

    static func renderLogo(stem: String) -> Never {
        let ok = write(Logo(dark: false), to: "\(stem)-light.png") && write(Logo(dark: true), to: "\(stem)-dark.png")
        exit(ok ? 0 : 1)
    }

    static func renderAppIcon(directory: String) -> Never {
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let sizes: [(String, CGFloat)] = [
            ("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64), ("128x128", 128),
            ("128x128@2x", 256), ("256x256", 256), ("256x256@2x", 512), ("512x512", 512), ("512x512@2x", 1024),
        ]
        var ok = true
        for (name, px) in sizes {
            ok = write(AppIcon().frame(width: px, height: px), to: "\(directory)/icon_\(name).png", scale: 1) && ok
        }
        exit(ok ? 0 : 1)
    }

    static func renderGuide(stem: String) -> Never {
        exit(write(Guide(), to: "\(stem).png", scale: 2) ? 0 : 1)
    }
}

/// The wordmark: lowercase standuppp, the last three p's hopping higher and higher, as if
/// getting up off a chair.
struct Wordmark: View {
    var size: CGFloat = 64
    var color: Color = Color(.sRGB, red: 0.15, green: 0.13, blue: 0.10)

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text("standu").foregroundStyle(color)
            ForEach(0..<3, id: \.self) { i in
                Text("p")
                    .foregroundStyle(i == 2 ? DuckFace.beak : color)
                    .rotationEffect(.degrees(Double(i + 1) * -6))
                    .offset(y: -CGFloat(i + 1) * size * 0.14)
                    .padding(.leading, size * 0.035 * CGFloat(i + 1))
            }
        }
        .font(.system(size: size, weight: .heavy, design: .rounded))
        .padding(.top, size * 0.4)
    }
}

struct Logo: View {
    let dark: Bool

    var body: some View {
        HStack(spacing: 28) {
            DuckFace(mood: .fresh, time: 1).frame(width: 150, height: 150)
            VStack(alignment: .leading, spacing: 6) {
                Wordmark(size: 72, color: dark ? Color(white: 0.95) : Color(.sRGB, red: 0.15, green: 0.13, blue: 0.10))
                Text("站站鸭 · Stand up. Laugh a little. Move a lot.")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(dark ? Color(white: 0.7) : Color(white: 0.4))
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
    }
}

struct AppIcon: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.225, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(.sRGB, red: 0.53, green: 0.82, blue: 0.98), Color(.sRGB, red: 0.33, green: 0.62, blue: 0.94)],
                        startPoint: .top, endPoint: .bottom))
                    .padding(s * 0.1)
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: s * 0.6, height: s * 0.12)
                    .offset(y: s * 0.27)
                DuckFace(mood: .fresh, time: 1)
                    .frame(width: s * 0.66, height: s * 0.66)
                    .offset(y: s * 0.02)
            }
        }
    }
}

/// The how-it-works picture at the top of the README.
struct Guide: View {
    private let ink = Color(.sRGB, red: 0.15, green: 0.13, blue: 0.10)
    private let muted = Color(white: 0.42)

    private struct Step: Identifiable {
        let id: Int
        let title: String
        let english: String
        let detail: String
        let mood: PetMood
    }

    private let steps = [
        Step(id: 1, title: "打开就在", english: "Lives in your menu bar",
             detail: "菜单栏一个小圆环，桌面一只站站鸭。\n不在程序坞，关掉窗口也不退出。", mood: .fresh),
        Step(id: 2, title: "安心工作", english: "Counts real work only",
             detail: "只算键盘鼠标真正在动的时间，\n默认 50 分钟（可调）。", mood: .focused),
        Step(id: 3, title: "鸭子来催", english: "Quacks when it's time",
             detail: "15 段搞笑小剧场随机播一段：\n音效 + 离谱台词 + 音效。", mood: .nudging),
        Step(id: 4, title: "真的起来", english: "Actually get up",
             detail: "离开键盘休息 5 分钟才算数；\n休息时敲键盘超过 1 分钟 = 作废。", mood: .resting),
        Step(id: 5, title: "回来看看", english: "See your day",
             detail: "今日活跃、最长连续、休息几次、\n做到几次，一眼看清。", mood: .proud),
        Step(id: 6, title: "随你调", english: "Make it yours",
             detail: "间隔、语言、宠物形象、音效、\n开机启动，全在设置里。", mood: .away),
    ]

    var body: some View {
        VStack(spacing: 34) {
            HStack(spacing: 22) {
                DuckFace(mood: .nudging, time: 1).frame(width: 120, height: 120)
                VStack(alignment: .leading, spacing: 8) {
                    Wordmark(size: 58, color: ink)
                    Text("别坐啦，起来笑一个！  Stand up. Laugh a little. Move a lot.")
                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                        .foregroundStyle(muted)
                }
                Spacer(minLength: 0)
            }
            Text("一只有点欠揍、但真的关心你屁股的 Mac 桌面宠物。它用搞怪鸭叫、离谱台词和可爱动画提醒你起身活动，而且只有你真的离开椅子，这次休息才算数。")
                .font(.system(size: 19, design: .rounded))
                .foregroundStyle(ink)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 22), count: 3), spacing: 22) {
                ForEach(steps) { step in card(step) }
            }
        }
        .padding(48)
        .frame(width: 1600)
        .background(
            LinearGradient(colors: [Color(.sRGB, red: 1, green: 0.98, blue: 0.9), Color(.sRGB, red: 0.95, green: 0.97, blue: 1)],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func card(_ step: Step) -> some View {
        HStack(alignment: .center, spacing: 18) {
            ZStack(alignment: .topLeading) {
                PetFace(mood: step.mood, time: 1).frame(width: 118, height: 118)
                Text("\(step.id)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(DuckFace.beak))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(ink)
                Text(step.english)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(DuckFace.beakDark)
                Text(step.detail)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(height: 190)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.white.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.black.opacity(0.06)))
    }
}
