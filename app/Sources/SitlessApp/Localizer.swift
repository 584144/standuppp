import Foundation
import SitlessCore

/// The Chinese interface. Every string the app draws is English in the source and goes
/// through `L` on its way to the screen: an exact match first, then the patterns below for
/// lines that carry a number or a name. Anything not listed stays English.
enum Localizer {
    nonisolated(unsafe) static var chinese = AppLanguage.system.isChinese

    static func translate(_ english: String) -> String {
        guard chinese, !english.isEmpty else { return english }
        if let found = lookup(english) { return found }
        // A sentence the menu ends with its own full stop: translate the sentence, keep the stop.
        if english.hasSuffix("."), let found = lookup(String(english.dropLast())) {
            return found.hasSuffix("。") ? found : found + "。"
        }
        return english
    }

    private static func lookup(_ english: String) -> String? {
        if let exact = exact[english] { return exact }
        let range = NSRange(english.startIndex..., in: english)
        for (regex, template) in patterns {
            guard let match = regex.firstMatch(in: english, range: range), match.range == range else { continue }
            var out = regex.replacementString(for: match, in: english, offset: 0, template: template)
            // Translate the captured pieces too, so "in a meeting" inside a line becomes Chinese.
            for (en, zh) in fragments where out.contains(en) { out = out.replacingOccurrences(of: en, with: zh) }
            return out
        }
        return nil
    }

    private static let patterns: [(NSRegularExpression, String)] = rawPatterns.compactMap { pattern, template in
        (try? NSRegularExpression(pattern: pattern)).map { ($0, template) }
    }

    private static let rawPatterns: [(String, String)] = [
        (#"^You set (\d+)\. At a (\d+)-minute interval that is spent before lunch, so it is raised to (\d+), about ([\d.]+) hours of work\. To be interrupted less, raise the interval\.$"#,
         "你设的是 $1 次。按 $2 分钟的间隔，午饭前就会用完，所以已调高到 $3 次，大约覆盖 $4 小时的工作。想少被打扰，请把间隔调长。"),
        (#"^About ([\d.]+) hours of work at the current interval\. After that the app goes quiet until 4am\.$"#,
         "按当前间隔大约够 $1 小时的工作。用完后 App 会安静到凌晨 4 点。"),
        (#"^macOS refused, (.*)$"#, "macOS 拒绝了：$1"),
        (#"^(\d+) of (\d+) earned$"#, "已获得 $1 / $2"),
        (#"^in (.*), matched by (.*)$"#, "在 $1 中，通过 $2 匹配"),
        (#"^Plain JSON, nothing encoded\. Raw events are kept for (\d+) days\. Daily summaries, which hold the seconds spent in each app, stay until you delete them\.$"#,
         "都是明文 JSON，没有任何编码。原始事件保留 $1 天。每日汇总（记录每个 App 用了多少秒）会一直保留，直到你删除。"),
        (#"^(.+) is the latest version\.$"#, "$1 已是最新版本。"),
        (#"^(.+) is available\.$"#, "$1 可以更新。"),
        (#"^(.+) is downloaded\. Installing checks its signature first\.$"#, "$1 已下载。安装前会先校验签名。"),
        (#"^(.+) is available but installs by hand\.$"#, "$1 可以更新，但需要手动安装。"),
        (#"^(.+) is verified and ready\.$"#, "$1 已校验，可以安装。"),
        (#"^([\d.]+) of ([\d.]+) MB$"#, "$1 / $2 MB"),
        (#"^on · (.*)$"#, "开 · $1"),
        (#"^(\d+) added$"#, "已添加 $1 个"),
        (#"^until (\d+:\d+) tomorrow$"#, "到明天 $1"),
        (#"^until (\d+:\d+)$"#, "到 $1"),
        (#"^asking again at (.*)$"#, "将在 $1 再次提醒"),
        (#"^(.+) planned, until (.*)$"#, "计划 $1，到 $2"),
        (#"^(.+) ago$"#, "$1 前"),
        (#"^(.+) of the break left$"#, "休息还剩 $1"),
        (#"^(.+) of the work target$"#, "已达工作目标的 $1"),
        (#"^(.+) past the work target$"#, "超出工作目标 $1"),
        (#"^confidence (.*)$"#, "置信度 $1"),
        (#"^(.+), a natural pause$"#, "$1，一个自然的停顿"),
        (#"^Update to (.+)…$"#, "更新到 $1…"),
        (#"^(.+), (.+) of (.+) active$"#, "$1，活跃 $3 中占 $2"),
        (#"^(\d+) of (\d+)$"#, "$1 / $2"),
        (#"^(.+) remaining of (.+)$"#, "还剩 $1，共 $2"),
        (#"^of (.+)$"#, "共 $1"),
        (#"^(.+) continuous$"#, "已连续工作 $1"),
        (#"^Skip, quiet for (.+)$"#, "跳过，安静 $1"),
        (#"^ignore it, and it leaves you alone for (.+)$"#, "不理它的话，它会安静 $1"),
        (#"^the break runs to (.*)$"#, "休息到 $1 结束"),
        (#"^you snoozed it, asking again at (.*)$"#, "你推迟了，将在 $1 再次提醒"),
        (#"^you paused it until (.*)$"#, "你暂停到了 $1"),
        (#"^your quiet hours end at (.*)$"#, "免打扰时段在 $1 结束"),
        (#"^(.+), so it leaves you alone until (.*)$"#, "$1，所以到 $2 之前不打扰你"),
        (#"^(.+), so the next break is (.+) later than usual$"#, "$1，所以下次休息比平时晚 $2"),
        (#"^next break in (.+) of work$"#, "再工作 $1 就该休息了"),
        (#"^you waved the last one off, and it has been due (.*)$"#, "你没理上一次提醒，已经超时 $1"),
        (#"^The (.+) prompt has nowhere to go: this Mac reports no screen\. It is not being counted against you\.$"#,
         "$1 提醒无处显示：这台 Mac 没有可用的屏幕。这次不会算在你头上。"),
    ]

    /// Pieces that show up inside pattern captures.
    private static let fragments: [(String, String)] = [
        ("under 1m", "不到 1 分钟"),
        ("in a meeting", "在开会"),
        ("in a call", "在通话"),
    ]

    private static let exact: [String: String] = [
        // Settings: panes
        "Rhythm": "节奏",
        "Voice": "语气",
        "Badges": "徽章",
        "Access": "权限",
        "Data": "数据",
        "About": "关于",
        "When a break is due, how long it lasts, and when the app should keep quiet.":
            "什么时候该休息、休息多久，以及什么时候保持安静。",
        "How hard the app is allowed to hit. A ceiling you set, never a floor it raises.":
            "提醒可以有多直接。这是你设的上限，App 不会自己往上加。",
        "Ten marks. Every one of them is for taking the break or for not needing it, and none of them is a streak.":
            "十枚徽章。每一枚都奖励休息或者不需要休息，没有一枚是连续打卡。",
        "What the app can see right now, what each thing costs you, and the switches that widen it.":
            "App 现在能看到什么，每一项需要你付出什么，以及扩大范围的开关。",
        "Everything the app keeps lives in one folder you can read with cat.":
            "App 保存的所有东西都在一个文件夹里，用 cat 就能读。",

        // Settings: section kickers
        "interval": "间隔",
        "quiet hours": "免打扰时段",
        "prompt": "提醒",
        "budget": "额度",
        "break": "休息",
        "1 break": "1 次休息",
        "system": "系统",
        "language": "语言",
        "tone": "语气",
        "escalation": "升级",
        "cannot see": "看不到的",
        "check it": "自己核对",
        "where it lives": "存放位置",
        "status line": "状态行",
        "export": "导出",
        "delete": "删除",
        "updates": "更新",
        "links": "链接",
        "built on": "依赖",
        "read": "读取",
        "Always on": "始终开启",
        "Needs Accessibility": "需要辅助功能权限",
        "Off by default": "默认关闭",

        // Settings: rhythm
        "Work interval": "工作间隔",
        "Continuous active work before a break is due. Reading a diff counts; the twenty minutes you spent in the kitchen does not.":
            "连续活跃工作多久后提醒休息。看代码也算；你在厨房待的二十分钟不算。",
        "min": "分钟",
        "max": "次",
        "Break length": "休息时长",
        "How long the process stays stopped before SIGCONT.": "每次休息持续多久。",
        "Stay quiet on a schedule": "按时段免打扰",
        "Inside the window the app still measures, still counts the break opportunity, and says nothing. Suppressed opportunities are excluded from compliance rather than counted as misses.":
            "时段内 App 仍然计时、仍然记下该休息的时机，但不出声。被静音的时机不计入统计，不会算作没休息。",
        "Window": "时段",
        "24-hour clock, local time. Wraps past midnight.": "24 小时制，本地时间。可以跨过午夜。",
        "Play a sound": "播放提示音",
        "Tink at SIGTSTP, Morse at SIGINT, Submarine at SIGTERM, Sosumi at SIGSTOP. The escalation is carried by volume. One quiet Glass when a break runs out on its own, never when you press SIGCONT. Silent while a microphone or camera is on, so it never lands in a call or a recording.":
            "提醒逐级升级时，提示音也会逐级变化。休息自然结束时轻响一声，手动结束时不响。麦克风或摄像头在用时保持静音，不会打扰通话或录音。",
        "Use macOS notifications instead": "改用 macOS 系统通知",
        "Off by default. An unsigned build's notification is reported as delivered and macOS never draws it, so on this build you see no banner and no panel until SIGSTOP. Leave it off unless you signed the app yourself.":
            "默认关闭。未签名的 App 发出的通知，macOS 会报告已送达但不显示，所以在最高一级之前你什么都看不到。除非你自己签名了 App，否则请保持关闭。",
        "Most prompts in a day": "每天最多提醒次数",
        "Show the full-screen overlay": "休息时显示全屏遮罩",
        "Dimmed, not opaque. The work is still there.": "半透明，不完全遮挡。你的工作还在后面。",
        "Suggest something to do": "建议休息时做点什么",
        "A small, finishable nudge to leave the chair.": "一个小小的、做得完的建议，让你离开椅子。",
        "Hold my break during calls": "通话时推迟休息",
        "After a microphone or camera stops, hold the prompt for up to 20 minutes in case you only muted. Turning it off also ends an \"I'm in a meeting\" hold, and turning it back on restores the feature. A live microphone or camera still blocks on its own, except on a Mac whose audio signal the app cannot trust, where this switch is the only thing holding; -\u{2060}-\u{2060}doctor says which one this is.":
            "麦克风或摄像头停用后，提醒最多再等 20 分钟，以防你只是静音了。关闭后也会结束\"我在开会\"的暂停。麦克风或摄像头正在使用时，本来就不会提醒。",
        "Appearance": "外观",
        "The app's own windows. The menu bar mark always matches the menu bar.": "App 自己窗口的外观。菜单栏图标始终跟随菜单栏。",
        "System": "跟随系统",
        "Light": "浅色",
        "Dark": "深色",
        "Show in the Dock": "在程序坞显示",
        "Off by default: the app lives in the menu bar and on the desktop pet, and closing a window never quits it. Turn it on if the menu bar hides its mark.":
            "默认关闭：App 只在菜单栏和桌面宠物上，关掉窗口也不会退出。如果菜单栏图标被挤掉了，可以打开它。",
        "Launch at login": "开机自动启动",
        "Launching at login needs the bundled app, build it with `make bundle`.": "开机启动需要打包后的 App，请用 `make bundle` 构建。",
        "Language": "界面语言",
        "Chinese for menus, settings and prompts, or follow macOS. Prompts in Chinese use a calm voice.":
            "菜单、设置和提醒用中文还是英文，或跟随系统。中文提醒使用温和的语气。",
        "Break counts only if you leave": "离开键盘才算休息",
        "If the keyboard or mouse is in use for longer than this during a break, the break does not count and the work clock keeps running.":
            "休息期间如果键盘鼠标累计使用超过这个时长，这次休息不算数，工作计时继续。",
        "sec": "秒",

        // Settings: voice
        "Friendly": "友好",
        "Sarcastic": "讽刺",
        "Roast": "吐槽",
        "Nuclear": "核弹",
        "polite": "礼貌",
        "default": "默认",
        "you asked": "你自找的",
        "theatrical": "夸张",
        "A colleague tapping you on the shoulder.": "像同事轻轻拍拍你的肩膀。",
        "A colleague who has watched you do this all week.": "像一个看你这样坐了一整周的同事。",
        "Your code reviewer, but about your posture.": "像你的代码审查人，只不过审的是你的坐姿。",
        "Pager duty for your spine. You asked for this.": "为你的脊椎值夜班。这是你自己选的。",
        "Your choice is a ceiling, never a floor. The rails apply at every tier: never about appearance, competence, or your job. NUCLEAR is theatrical, not cruel.":
            "你选的是上限，不是下限。任何语气都不会评论你的外表、能力或工作。中文界面目前只有一套温和的提醒语，不受这里的选择影响。",
        "If a prompt is ignored the ladder climbs one signal per rung, SIGTSTP, SIGINT, SIGTERM, then SIGSTOP, ordered by how easy each is to ignore. It stops there, at the one signal that cannot be ignored and destroys nothing.":
            "如果提醒被忽略，它会一级一级升级，一共四级，越往上越难忽略。到第四级就停止升级。",

        // Settings: badges
        "Nothing here rewards working longer, because the app exists to interrupt long stretches and paying you for one would have it arguing with itself. yielded is the clearest case: it is for a full day where nothing ran past the hour.":
            "这里没有任何徽章奖励更长时间的工作，因为这个 App 本来就是要打断久坐的。",
        "There is no streak. Nothing expires, missing a day costs nothing, and none of these can go down once it has happened. Every one is counted from the log already on disk; no new tracking was added for them.":
            "没有连续打卡。徽章不会过期，漏掉一天也没关系，拿到了就不会失去。全部根据本机已有的日志计算，没有额外追踪。",
        "not yet": "尚未获得",
        "Take one break.": "休息一次。",
        "Ten breaks in total. The count is in the name.": "累计休息十次。",
        "One day where every break offered was taken.": "有一天，每次提醒的休息都做到了。",
        "Ten days where every break offered was taken.": "有十天，每次提醒的休息都做到了。",
        "Accept five prompts within fifteen seconds of being asked.": "五次在提醒出现十五秒内接受休息。",
        "Let one prompt reach the fourth rung, SIGSTOP.": "让一次提醒升级到第四级。",
        "A day of at least four hours where no single stretch passed an hour.": "某天工作至少四小时，但没有一次连续超过一小时。",
        "Take a break before 10:00 on five separate days.": "在五个不同的日子里，上午 10 点前休息过。",
        "Take a break after 01:00 on five separate days.": "在五个不同的日子里，凌晨 1 点后休息过。",
        "A hundred breaks in total.": "累计休息一百次。",
        "Your first break. It is what the shell prints when a job is suspended, and the job is fine: registers, memory, all of it still there.":
            "你的第一次休息。暂停不是放弃，手上的一切都还在。",
        "Ten breaks. Ten times you took your own priority down a step, and nobody else had to do it for you.":
            "十次休息。十次你主动停下来，不需要别人提醒第二遍。",
        "A day where every break the app actually asked for happened. Nothing deferred, nothing pending, nothing in the way.":
            "这一天，每次提醒的休息都做到了。没有拖延，没有欠账。",
        "Ten of those days. Whether an arbitrary program halts is undecidable. You are not an arbitrary program, and this is ten days of evidence.":
            "这样的日子有十天了。你会按时停下来，这是十天的证据。",
        "Five prompts accepted inside fifteen seconds. Nothing caught them, nothing thought about them, the default just ran.":
            "五次在十五秒内就接受了休息。没有犹豫，直接起身。",
        "You let one prompt climb all four rungs. The top one cannot be caught, blocked or ignored by anybody, ever, and the kernel will not even let you try to install a handler for it.":
            "你让一次提醒升到了第四级。到这一级，谁也拦不住它。",
        "Four hours of work and not one stretch past the hour. You handed the slot back before anything had to take it from you.":
            "工作了四小时，没有一次连续超过一小时。你总是主动停下来。",
        "Five days with a break before ten in the morning. Out before the branching got complicated.":
            "五天在上午十点前就休息过一次。在事情变复杂之前先起身。",
        "Five nights with a break after one in the morning. The terminal is closed and the link to it is cut: the job is the thing still running, and you are the part that stopped.":
            "五个深夜在凌晨一点后还记得休息。不过，也该早点睡了。",
        "A hundred breaks. The shell prints the same line it printed the first time. Only the number in the brackets moved.":
            "一百次休息。和第一次一样，只是数字变大了。",

        // Settings: access
        "macOS cannot limit this permission to window titles. Granting it means trusting this code, not the operating system. And until sitless is signed with an Apple Developer ID, anything already running as you could borrow the grant by running a modified copy of the app. The app works without it; only the two rows below want it.":
            "macOS 无法把这个权限限制在窗口标题上。授予它意味着你信任这份代码，而不是信任系统。App 不需要它也能正常工作，只有下面两项会用到。",
        "Accessibility": "辅助功能",
        "The grant. The app never shows the macOS alert itself; the button opens the switch.": "授权状态。App 不会自己弹出系统授权框，按钮会打开对应的开关。",
        "Re-check": "重新检查",
        "Open System Settings": "打开系统设置",
        "No permission is involved. Two switches, because they read different things and agreeing to one is not agreeing to the other.":
            "不涉及任何系统权限。分成两个开关，因为它们读取的东西不同。",
        "Project folders": "项目文件夹",
        "The whole of what the branch reader may open. Pick the root of a repository; the folder you choose is the grant.":
            "读取分支名时只会打开这些文件夹。请选择仓库的根目录。",
        "Add project folder…": "添加项目文件夹…",
        "Remove": "移除",
        "Screen sharing": "屏幕共享",
        "No permission-free signal exists, so it is reported as unknown, never as no. When presenting, use \u{201C}I'm in a meeting\u{201D} in the menu.":
            "不申请权限就无法得知，所以显示为\"未知\"。演示时请在菜单里点\"我在开会\"。",
        "unknown": "未知",
        "Never requested: Screen Recording, Input Monitoring, Full Disk Access, Automation, Calendar, Contacts, Microphone, Camera, Location. Their usage strings are absent from Info.plist, so an attempt would crash the app rather than prompt you.":
            "从不申请：屏幕录制、输入监控、完全磁盘访问、自动化、日历、通讯录、麦克风、摄像头、位置。",
        " prints every row on this page with the macOS call behind it.": " 会打印本页每一项，以及背后调用的 macOS 接口。",
        "The full inventory": "完整清单",
        "docs/PRIVACY.md: every datum, the API that produces it, where it goes and for how long":
            "docs/PRIVACY.md：每一项数据、来源接口、存放位置和保留时长",
        "The one file that reads a window": "唯一读取窗口的文件",
        "two attributes, one private reader, and the function that keeps only the host": "两个属性、一个私有读取器，以及只保留域名的函数",
        "not sampled yet": "尚未采样",
        "on": "开",
        "off": "关",
        "granted": "已授权",
        "not granted": "未授权",
        "none yet": "暂无",
        "front app, idle time, screen lock, mic and camera, power": "前台 App、空闲时间、锁屏、麦克风和摄像头、电源",
        "window titles": "窗口标题",
        "browser host": "浏览器域名",
        "branch name": "分支名",
        "tool names": "工具名",
        "Front app, idle time, screen lock, mic and camera, power": "前台 App、空闲时间、锁屏、麦克风和摄像头、电源",
        "Window titles": "窗口标题",
        "Browser host": "浏览器域名",
        "Branch name": "分支名",
        "Tool names": "工具名",
        "needs window titles": "需要先开窗口标题",
        "no project folder added": "还没添加项目文件夹",
        "No permission and no prompt. Which app and for how long, whether you are at the keyboard, whether a mic or camera is live and which app holds the mic. Never what is in the window.":
            "无需权限，不会弹窗。读取前台是哪个 App、用了多久、你是否在键盘前、麦克风或摄像头是否在用。从不读取窗口内容。",
        "Two attributes of the front window, its title and its document path. Kept in memory until the next read, at most a minute while you are active; nothing from either reaches the disk.":
            "前台窗口的标题和文档路径。只在内存中保留到下一次读取，不写入磁盘。",
        "The host of the page in front, github.com, from the same document attribute. The path and the query are dropped in the function that parses them.":
            "前台网页的域名（例如 github.com）。路径和参数在解析时就丢弃了。",
        "One line of .git/HEAD in the folders you added, and whether a rebase, merge or bisect is under way. Never a diff, a commit or a git command.":
            "只读你添加的文件夹里 .git/HEAD 的一行，以及是否在 rebase/merge/bisect。从不读 diff、提交，也不运行 git 命令。",
        "Executable names against a fixed list in the source, plus the kernel's under-a-debugger flag. Never a command line. Without it the app says coding rather than guess at debugging.":
            "对照源码里的固定列表检查可执行文件名，以及是否处于调试中。从不读取命令行参数。",

        // Settings: data
        "one file per day, appended, never rewritten": "每天一个文件，只追加，不改写",
        "one object per day: seconds per app and per activity, break counts, kept until you delete them": "每天一条：每个 App 和每种活动的秒数、休息次数，保留到你删除为止",
        "which of the ten unlocked, and when": "解锁了哪些徽章、什么时候",
        "today's budgets: prompts delivered, cycles unanswered, the compliance tally": "今天的计数：发出的提醒、未回应的次数、完成情况",
        "seconds a call has held a break today; exists once one has": "今天因通话推迟休息的秒数；发生过才会有",
        "exactly what the panes above set": "就是上面这些设置",
        "one line for tmux or your prompt; exists while the switch below is on and sitless runs": "给 tmux 或终端提示符用的一行状态；下面的开关打开时才有",
        "empty; held while sitless runs, so a second copy leaves": "空文件；运行时占用，防止重复启动",
        "Write a status line for tmux or your prompt": "为 tmux 或终端提示符写状态行",
        "The state word and the waiting line from the menu, rewritten only when they change and removed when this is off or sitless quits. Never a project, a branch, a file or a title.":
            "内容是菜单里的状态和下一步提示，变化时才改写，关闭或退出时删除。从不包含项目、分支、文件或标题。",
        "The event log as one text file, as sitless reads it: every line that parses, in time order within each day. A line that does not parse is left out and counted at the top, and a field this version does not know is dropped. For the bytes themselves, read the files in events/.":
            "把事件日志导出成一个文本文件：每天按时间排序，无法解析的行会跳过并在开头计数。想看原始内容，请直接读 events/ 里的文件。",
        "Export…": "导出…",
        "Removes everything in the folder above except its empty .lock: the event log, the summaries, the badges, the day's counters, the call hold's total for today and these settings. There is no archive, no tombstone and no copy kept anywhere, which is the point and also means there is no undo.":
            "删除上面文件夹里除空 .lock 以外的所有内容：事件日志、汇总、徽章、当天计数、通话推迟记录和这些设置。不留任何备份，所以无法撤销。",
        "Delete my data…": "删除我的数据…",
        "Add": "添加",
        "Pick the root of a repository. sitless reads only git's own small files: the first line of HEAD, the .git file of a worktree or submodule (at most 512 bytes), and during a rebase the branch name. It never opens a file of yours.":
            "请选择仓库根目录。只会读 git 自己的几个小文件，从不打开你的文件。",
        "The event log as one readable file: every event that parses, in time order.": "把事件日志导出为一个可读文件，按时间排序。",
        "Delete everything sitless has stored?": "删除久坐工具提醒保存的所有数据？",
        "This removes everything in the folder sitless keeps its data in: the event log, the daily summaries, the badges, the day's counters, the call hold's total for today and your settings. Only its empty .lock stays, because sitless is still running. There is no archive, no tombstone and no copy kept anywhere.":
            "这会删除数据文件夹里的所有内容：事件日志、每日汇总、徽章、当天计数、通话推迟记录和你的设置。只保留空的 .lock，因为 App 还在运行。不留任何备份。",
        "Delete": "删除",
        "Cancel": "取消",

        // Settings: about
        "development build": "开发版",
        "A stopped process keeps everything and continues at the exact instruction.": "停下来不会丢失任何东西，回来时从原处继续。",
        "Source on GitHub": "GitHub 源码",
        "every line of this, including the parts that are wrong": "每一行代码，包括写错的部分",
        "Architecture docs": "设计文档",
        "why it decides what it decides, written before the code": "它为什么这样判断，写在代码之前",
        "What it collects": "收集了什么",
        "the full inventory, and the one thing that leaves the machine": "完整清单，以及唯一会离开本机的东西",
        "Report a bug": "报告问题",
        "run the doctor first, it prints everything this app can see": "先运行 --doctor，它会打印 App 能看到的一切",
        "The only third-party code in the app, and the only thing in it that can open a socket. It refuses any update whose signature does not verify against a key compiled into this binary.":
            "App 里唯一的第三方代码，也是唯一能联网的部分。签名校验不通过的更新一律拒绝。",
        "Used if you already have it. Nothing is downloaded and no font is bundled: without it this falls back to the system monospace.":
            "如果你已经装了就会使用。不会下载，也不内置字体，没有时使用系统等宽字体。",
        "A fork of sigstop by": "fork 自 sigstop，原作者",
        "Download": "下载",
        "Not now": "暂不",
        "Install": "安装",
        "Later": "稍后",
        "Install and restart": "安装并重启",
        "Open releases in browser": "在浏览器中打开发布页",
        "Check for updates": "检查更新",
        "Working…": "处理中…",
        "Try again": "重试",
        "Nothing has been checked yet.": "还没有检查过。",
        "Asking the feed…": "正在检查…",
        "Downloading…": "正在下载…",
        "Checking the signature, then unpacking…": "正在校验签名并解压…",
        "Installing. sitless will restart itself.": "正在安装，App 会自动重启。",

        // Menu bar
        "running": "工作中",
        "break due": "该休息了",
        "escalating": "提醒升级中",
        "snoozed": "已推迟",
        "stopped": "休息中",
        "idle": "离开中",
        "paused": "已暂停",
        "stood down": "暂不提醒",
        "quiet": "免打扰",
        "starting up": "启动中",
        "state T": "休息",
        "state R": "工作",
        "state S": "空闲",
        "SIGALRM": "推迟",
        "left": "剩余",
        "no work target in force": "当前没有工作目标",
        "at the work target": "刚好达到工作目标",
        "last break": "上次休息",
        "none recorded yet": "还没有记录",
        "app": "应用",
        "nothing sampled yet": "尚未采样",
        "activity": "活动",
        "why do you think that?": "为什么这么判断？",
        "conf": "置信",
        "No evidence either way yet.": "还没有足够的依据。",
        "Take a break now": "现在就休息",
        "Resume · SIGCONT": "结束休息",
        "Resume": "继续",
        "Not in a meeting": "我没在开会",
        "I'm in a meeting": "我在开会",
        "Pause · 1h": "暂停 1 小时",
        "Pause · today": "今天暂停",
        "Settings…": "设置…",
        "Quit": "退出",
        "uptime · today": "今日 · 活跃",
        " active": " 活跃",
        "Nothing recorded yet today.": "今天还没有记录。",
        "top": "最常用",
        "longest": "最长连续",
        "breaks": "休息次数",
        "avg break": "平均休息",
        "kept": "做到",
        "held": "暂缓",
        "waiting on you": "等你行动",
        "a break is due and you are away": "该休息了，而你正好不在",
        "the work clock is stopped while you are away": "你不在时，工作计时暂停",
        "you paused it": "你暂停了提醒",
        "you have been asked": "已经提醒过你了",
        "this one gets a single prompt and has had it": "这次只提醒一遍，已经提醒过了",
        "a break is due and nothing is holding it": "该休息了，没有什么理由再推迟",
        "coding": "写代码",
        "debugging": "调试",
        "running tests": "跑测试",
        "reviewing code": "看代码",
        "in the terminal": "用终端",
        "pair-programming with an AI": "和 AI 结对编程",
        "writing docs": "写文档",
        "browsing": "浏览网页",
        "in chat": "聊天",
        "in a meeting": "开会",
        "away": "离开",
        "working": "工作",

        // Break screen and prompt panel
        "STATE T · SIGSTOP": "休息时间",
        "SIGTSTP": "提醒",
        "SIGINT": "再次提醒",
        "SIGTERM": "该休息了",
        "SIGSTOP": "必须休息",
        "Your process is stopped, not killed. SIGCONT resumes.": "只是暂停，什么都不会丢。点\"结束休息\"回来。",
        "remaining": "剩余",
        "SIGCONT": "结束休息",
        "Take it": "去休息",
        "Snooze (SIGALRM)": "稍后提醒",
        "Ignore it": "忽略",
        "ignore it, and it asks again in a few minutes": "不理它的话，几分钟后会再提醒",
        "ignore it, and nothing more today: the cap is spent": "不理它的话，今天就不再提醒了：额度已用完",
        "Stand up.": "站起来。",
        "Look at something further away.": "看看远处的东西。",
        "Stand up. The stack is saved.": "站起来，进度都保存着呢。",
        "Look out a window. Anything past arm's reach.": "看看窗外，任何比手臂远的地方都行。",
        "Both feet on the floor, then stand.": "双脚踩地，然后站起来。",
        "Refill your water.": "去续杯水。",
        "Walk to the furthest room and come back.": "走到最远的房间再回来。",
        "Open a window.": "开一下窗。",
        "Put the mug in the sink. Yes, that one.": "把杯子拿去水池。对，就是那个。",
        "Stand somewhere you can see outside.": "站到能看到外面的地方。",
        "Take the stairs to nowhere in particular.": "随便走走楼梯。",
        "Say the last thing you were doing out loud. It will still be there.": "把刚才在做的事说出来，它会一直在那等你。",

        "sitless Settings": "久坐工具提醒 设置",
        "Hide pet": "隐藏宠物",
        "Show pet": "显示宠物",
        "Hide the pet": "隐藏宠物",
        "Show the desktop pet": "显示桌面宠物",
        "A small companion floating on the desktop whose face follows how long you have sat. Drag it anywhere; click for today's numbers, double-click to start a break, right-click to hide it. It never takes focus and stays out of screen recordings.":
            "桌面上的一个小伙伴，表情跟着你坐了多久变化。可以拖到任何位置；单击看今天的数据，双击开始休息，右键可以隐藏。它不会抢走焦点，也不会出现在录屏和屏幕共享里。",
        "Time to stand up!": "该起来动动啦！",
        "zZ…": "zZ…",
        "Nice break!": "休息得真棒！",
        "That break didn't count…": "一直敲键盘，不算数哦…",
        "Getting stiff…": "坐得有点僵了…",
        "Pet, fresh": "宠物，精神饱满",
        "Pet, focused": "宠物，专心中",
        "Pet, tired": "宠物，有点累了",
        "Pet, asking you to stand up": "宠物，在叫你起来",
        "Pet, asleep": "宠物，睡着了",
        "Pet, proud of your break": "宠物，为你的休息骄傲",
        "Pet, sulking": "宠物，不开心",
        "Pet, waiting": "宠物，等你回来",
        "sitless": "久坐工具提醒",
    ]
}

/// The string to draw for this English source string, in the language the settings chose.
func L(_ english: String) -> String { Localizer.translate(english) }
