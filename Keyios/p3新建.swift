// ============================================================================
// 【新建页】—— 占位，还没做
// ============================================================================
// 从哪进来：日记列表页底部条的 `+` 按钮 -> 从底部升起这一页（sheet）
// 在这里继续做：把下面的"占位"部分换成真正的 UI
//
// 将来这一页要干的事（见 mvp.md）：
//   输入第一行内容 -> 落成一个新的 .dog 文件（文件名 = root 文本）
// ============================================================================

import SwiftUI

struct NewNoteView: View {

    /// 系统提供的"关掉我自己"的方法。从底部升起来的页面不是 push 进栈的，
    /// 所以不能靠返回按钮，得自己调用 dismiss。
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("📝 新建页（占位）")
                    .font(.title2)
                    .foregroundStyle(Theme.primaryText)

                Text("将来在这里：输入内容 → 生成新的 .dog 文件")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)

                Text("代码在 Keyios/NewNoteView.swift")
                    .font(.footnote)
                    .foregroundStyle(Theme.accent)

                Button("关闭") { dismiss() }
                    .foregroundStyle(Theme.accent)
                    .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// #Preview：不是 app 会跑的代码，只是给编辑器/预览工具"单独画这一屏"用。
// 有它就能不跑整个 app、直接看这一页长什么样。
// （完整说明见 DiaryListView.swift 末尾）
// ────────────────────────────────────────────────────────────────────────────
#Preview {
    NewNoteView()
}
