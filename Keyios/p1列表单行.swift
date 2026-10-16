// ============================================================================
// 【列表里的一行】长什么样
// ============================================================================
// 目标长相（对齐 Keynote 稿）：
//
//     ( 今天   10:12 买菜   11:22 洗衣服 )
//       ↑绿色   ↑灰色 ↑白色
//
// 一行 = 缩减后的文件名 + 最多 3 条摘要，每条摘要 = 时间 + 文本。
// ============================================================================

import SwiftUI

struct DiaryRowView: View {

    let entry: DiaryEntry

    // `var body: some View` 是 SwiftUI 每个视图的固定写法：
    // "我这个视图长什么样"。里面就是把它拼出来。
    var body: some View {

        // HStack = 横向排列（像 QHBoxLayout），spacing 是子元素间距
        HStack(spacing: 10) {

            // 文件名：缩减过的，主色绿，加粗
            Text(DiaryNameAbbreviator.abbreviate(entry.fileName))
                .foregroundStyle(Theme.accent)
                .fontWeight(.semibold)

            // `prefix(3)` = 最多取前 3 条（不够 3 条就有几条算几条）
            ForEach(entry.summaries.prefix(3)) { s in
                HStack(spacing: 4) {
                    Text(s.time).foregroundStyle(Theme.secondaryText)   // 时间：灰
                    Text(s.text).foregroundStyle(Theme.primaryText)     // 正文：白
                }
            }
        }
        .font(.system(size: 15))
        .lineLimit(1)       // 一行放不下就截断（不折行）。想改成允许折两行就删掉这行。
        .frame(maxWidth: .infinity, alignment: .leading)

        // 内边距：上下 13、左右 14。数字直接改就能看效果。
        .padding(.vertical, 13)
        .padding(.horizontal, 14)

        // 背景：圆角胶囊。Capsule() 是"两头半圆"的形状。
        // 想改成"描边"就把 fill 换成 stroke：
        //     Capsule().stroke(Theme.accent)
        .background(Capsule().fill(Theme.rowBackground))
    }
}

// ────────────────────────────────────────────────────────────────────────────
// #Preview：不是 app 会跑的代码，只是给编辑器/预览工具"单独画这一屏"用。
// 这里挑了三行不同"时间远近"的（今天 / 昨天 / 本月7日），方便一眼看出
// 文件名缩减后长短不一、摘要条数不一样时长什么样。
// （完整说明见 p1列表.swift 末尾）
// ────────────────────────────────────────────────────────────────────────────
#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack(spacing: 8) {
            DiaryRowView(entry: sampleDiaries[0])
            DiaryRowView(entry: sampleDiaries[1])
            DiaryRowView(entry: sampleDiaries[7])
        }
        .padding(.horizontal, 12)
    }
    .preferredColorScheme(.dark)
}
