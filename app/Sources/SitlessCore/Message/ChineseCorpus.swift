import Foundation

/// The prompts the Chinese interface uses: one calm voice, no app or activity guesses, so
/// every line fits whatever is on screen. The English corpus.json stays as it is.
extension Corpus {
    public static let chineseCalm = Corpus(packs: [
        MessagePack(
            packId: "sitless.zh-Hans.calm",
            locale: "zh-Hans",
            title: "温和提醒",
            messages: ChineseLines.all
        ),
    ], fallbacks: ChineseLines.all.map(\.asFallback))
}

private extension MessageTemplate {
    var asFallback: MessageTemplate {
        MessageTemplate(
            id: id + ".fallback", title: title, text: text, tone: tone, category: category,
            escalation: EscalationLevel.first ... EscalationLevel.incident, isFallback: true
        )
    }
}

enum ChineseLines {
    private static func line(
        _ id: String, _ title: String, _ text: String, _ levels: ClosedRange<EscalationLevel>
    ) -> MessageTemplate {
        MessageTemplate(
            id: "zh.calm.\(id)", title: title, text: text,
            tone: .friendly, category: "zh_calm", escalation: levels
        )
    }

    static let all: [MessageTemplate] = [
        line("stand-up", "该起来活动一下了", "坐了挺久了，站起来伸个懒腰吧。", .first ... .second),
        line("water", "喝口水吧", "去倒杯水，顺便走两步。回来时手上的事还在原地等你。", .first ... .second),
        line("window", "看看远处", "让眼睛离开屏幕，看看窗外最远的地方，二十秒就好。", .first ... .second),
        line("shoulders", "放松一下肩膀", "转转肩膀，动动脖子，然后起身走一走。", .first ... .second),
        line("saved", "先停一下", "进度不会跑掉。起来活动几分钟，再回来接着做。", .first ... .third),
        line("walk", "走一走", "到房间另一头走个来回，比继续坐着更有用。", .first ... .third),
        line("breathe", "深呼吸", "站起来，慢慢深呼吸三次，再决定接下来做什么。", .first ... .second),
        line("stretch", "伸展一下", "双手举过头顶，向上拉伸，腰背会感谢你的。", .first ... .second),
        line("eyes", "眼睛需要休息", "眼睛盯屏幕太久了，闭眼一会儿，或者看看绿色的东西。", .first ... .second),
        line("legs", "动动腿", "腿坐麻了吧？起来走几步，让血液流动起来。", .first ... .third),
        line("tea", "泡杯茶", "去泡杯茶或接杯水，等水的时候顺便站一会儿。", .first ... .second),
        line("posture", "换个姿势", "离开椅子几分钟，回来时坐得会更舒服。", .first ... .second),
        line("five", "几分钟就够", "不用很久，几分钟就好。站起来，离开座位。", .second ... .third),
        line("still-here", "还在坐着", "提醒过一次了，现在真的该起来了。休息完再回来效率更高。", .second ... .third),
        line("thinking", "换个地方想", "卡住的问题，站起来走一圈往往就想通了。", .second ... .third),
        line("body-first", "身体优先", "连续坐太久对腰和颈椎都不好。先照顾身体，工作随后。", .second ... .incident),
        line("one-break", "就这一次", "这次休息只要几分钟。起身、走动、喝水，然后回来。", .third ... .incident),
        line("really", "真的该休息了", "已经连续坐了很久。请离开键盘，让身体动一动。", .third ... .incident),
        line("away", "离开屏幕", "现在请离开屏幕和键盘。休息期间一直敲键盘，这次休息可不算数哦。", .third ... .incident),
        line("last", "最后一次提醒", "今天的提醒快用完了。起身活动一下，对自己好一点。", .incident ... .incident),
    ]
}
