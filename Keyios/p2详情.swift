// ============================================================================
// 【日记详情页】—— 占位，还没做
// ============================================================================
// 从哪进来：在日记列表页点某一行 -> 推进这一页（NavigationStack 的 push）
// 在这里继续做：把下面的"占位"部分换成真正的 UI
//
// 将来这一页要干的事（见 mvp.md / keyios.dog）：
//   * 展示整篇日记的树（缩进 + 圆点，圆点按级别缩小、按一级祖先上色）
//   * 多行节点先缩成一行，点开才展开为多行，此时才能编辑
//   * 编辑用 TextField(axis: .vertical)，纯文本
//
// 这一页是"头部要不要放返回按钮"的例外 —— 列表页按设计没有头部，
// 但推进来的页面必须有返回的路，所以这里保留系统导航栏。
// ============================================================================

import SwiftUI

struct DiaryDetailView: View {

    /// 点的是哪一篇。列表页推进来的时候传进来。
    let entry: DiaryEntry

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("📖 详情页（占位）")
                    .font(.title2)
                    .foregroundStyle(Theme.primaryText)

                Text(DiaryNameAbbreviator.abbreviate(entry.fileName))
                    .font(.headline)
                    .foregroundStyle(Theme.accent)

                Text(entry.fileName)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)

                Text("将来在这里：整篇日记的树 / 折叠 / 编辑")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)

                Text("代码在 Keyios/DiaryDetailView.swift")
                    .font(.footnote)
                    .foregroundStyle(Theme.accent)
            }
            .padding()
        }
        .navigationTitle(DiaryNameAbbreviator.abbreviate(entry.fileName))
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// #Preview：不是 app 会跑的代码，只是给编辑器/预览工具"单独画这一屏"用。
// 外面包一层 NavigationStack 是因为这一页依赖于"被推进来"（要有导航栏和返回键），
// 不包的话预览里就看不到导航栏。
// （完整说明见 DiaryListView.swift 末尾）
// ────────────────────────────────────────────────────────────────────────────
#Preview {
    NavigationStack {
        DiaryDetailView(entry: sampleDiaries[0])
    }
    .preferredColorScheme(.dark)
}
