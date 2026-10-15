// ============================================================================
// 【日记列表页】—— 目前唯一做完的页面（见 mvp.md）
// ============================================================================
// 设计要点：
//   * 背景黑，主色绿
//   * **头部不放任何点击区**（为了单手操作），所有操作都在底部浮动条上
//   * 列表全屏，每行 = 文件名（缩减过）+ 最多 3 条摘要
//
// 这一页还负责"当爹"：底部条上的搜索/新建、列表行的点击，都由它来响应。
// ============================================================================

import SwiftUI

struct DiaryListView: View {

    /// 要显示的日记。现在从外面传（App 里传的假数据），以后换成从 iCloud 读的 dog 文件。
    let diaries: [DiaryEntry]

    // ── 状态 ──
    // `@State` = "这个值会变，变了就重画界面"。
    // 类比 Qt：相当于一个信号量，只不过你不用手动 connect/emit，SwiftUI 自动盯着。
    //
    // 用 `private` 是因为这些值只属于这一页，外面（App）不需要也不该碰。
    @State private var searchText = ""          // 搜索框里打的字
    @State private var isSearching = false      // 搜索开着吗？(点底部放大镜时置 true)
    @State private var showingNewNote = false   // 新建页弹出来了吗？
    @State private var path: [DiaryEntry] = []  // 导航栈：点进详情页时往里塞一条

    /// 按搜索词过滤后的列表。
    /// 平时原样返回；搜索时只留对得上的行。
    /// `guard` = "不满足就立刻返回"，省掉一层 if 嵌套。
    private var filtered: [DiaryEntry] {
        guard isSearching, !searchText.isEmpty else { return diaries }
        return diaries.filter { entry in
            DiaryNameAbbreviator.abbreviate(entry.fileName).contains(searchText)  // 缩减后的名字
                || entry.fileName.contains(searchText)                            // 原始文件名
                || entry.summaries.contains { $0.text.contains(searchText) }      // 任一条摘要
        }
    }

    var body: some View {
        // NavigationStack 管"页面推进/返回"。path 是当前的页面栈。
        NavigationStack(path: $path) {
            ZStack {
                Theme.background.ignoresSafeArea()
                listContent
            }

            // ── 搜索：交给系统，不自己写 ──
            // `.searchable` 是系统给的搜索能力：搜索框长什么样、放在屏幕哪儿、
            // 键盘怎么弹、点外面怎么关，全归系统管。
            //
            // 为什么必须用它而不是自己搭一个输入框：
            // 自己搭就等于把"搜索该长什么样"这个决定**冻结在我写代码那天**，
            // 以后 iOS 改了搜索的位置和样式，我的代码不会跟着变。
            // 系统版会跟着系统版本自动变 —— iOS 26 的搜索框位置就跟以前不一样了。
            //
            // `isPresented: $isSearching` 让我们能从外面控制"搜索开不开"，
            // 底部那个放大镜按钮就是靠它把搜索唤起/收起的。
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "搜索日记")
            // 让搜索平时"收成一个按钮"，点开才展开成输入框。
            // 不加这行的话它会常驻占着屏幕底部一整条（之前的截图就是这样）。
            .modifier(MinimizedSearchField())

            // 点列表某行 -> path 里加一条 -> 自动推进详情页
            .navigationDestination(for: DiaryEntry.self) { entry in
                DiaryDetailView(entry: entry)
            }

            // `+` 按钮 -> 从底部升起新建页
            .sheet(isPresented: $showingNewNote) {
                NewNoteView()
            }

            // 这一页不要系统"顶部"导航栏 —— 设计里头部不放任何东西。
            // 注意：`.bottomBar`（底部那条）不受这行影响，它们是两码事。
            .toolbar(.hidden, for: .navigationBar)

            // 底部那条按钮。内容在 BottomBar.swift 里定义。
            .toolbar {
                BottomBar(
                    onSearch: { isSearching = true },
                    onNew:    { showingNewNote = true }
                )
            }
            // 系统底栏默认用系统色（白/灰），不认识我们的绿。
            // `.tint` 是"告诉系统这一片的主色是什么"，系统会把它用到按钮、光标等处。
            .tint(Theme.accent)
        }
        .preferredColorScheme(.dark)   // 强制深色（我们的设计本来就是黑底）
    }

    // MARK: - 列表本体

    private var listContent: some View {
        // ScrollView + LazyVStack：自己拼的滚动列，行样式完全自由。
        // Lazy = 只渲染屏幕上看得见的行，长列表才不卡。
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filtered) { entry in
                    DiaryRowView(entry: entry)
                        .contentShape(Capsule())          // 让整条胶囊都可点（默认只有文字可点）
                        .onTapGesture { path.append(entry) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 8)    // 底部条的避让由系统自己处理，这里只要一点余量
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// 【iOS 版本差异的一个例子】—— 为什么这里要包一层
// ────────────────────────────────────────────────────────────────────────────
// `.searchToolbarBehavior` 是 iOS 26 才加的 API。我们的最低支持版本是 iOS 17，
// 所以在老系统上不能直接调用它，得用 `if #available` 判断。
//
// `ViewModifier` 就是"一段可复用的修饰"：写一次，以后想给别的视图加同样的行为
// 就 `.modifier(MinimizedSearchField())`。这里包它纯粹是为了能塞进版本判断
// （`if #available` 不能直接写在修饰符链中间）。
// ────────────────────────────────────────────────────────────────────────────
private struct MinimizedSearchField: ViewModifier {

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // minimize = 不用的时候把搜索框收成一个小按钮
            content.searchToolbarBehavior(.minimize)
        } else {
            content          // iOS 17~25 没这个 API，原样返回
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// 【#Preview 是干嘛的】—— 下面这段不是 app 会跑的代码
// ────────────────────────────────────────────────────────────────────────────
// 它声明"这一坨是给预览用的"，作用只有一个：
//   让编辑器和预览工具（Xcode 画布、axe 之类）能单独画出这一屏，不用跑整个 app。
//
// 写不写都不影响 app 正常运行 —— 它纯粹是"想单独看这一屏长什么样"时省事用的。
// 习惯上每个界面文件末尾都配一个。
// ────────────────────────────────────────────────────────────────────────────
#Preview {
    DiaryListView(diaries: sampleDiaries)
}
