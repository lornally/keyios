// ============================================================================
// 【底部按钮条】—— 全交给系统的 toolbar
// ============================================================================
// 从左到右，**按重要性排**：
//
//     🔍   ＋   待办   持续   暂缓   完成   全部
//
// ── 为什么按重要性排 ────────────────────────────────────────────────────
// 因为 iPhone 的宽度是有限的，按钮多了**一定会放不下**。放不下时系统会自己
// 把末尾的几个收进一个「···」溢出菜单里 —— 这是系统的行为，不用我们写。
//
// 所以我们唯一要做的决定就是：**谁排前面**。排前面的永远露脸，
// 排后面的会在窄屏上被自动收进 ···。上面这个顺序 = 越靠左越重要。
//
// 千万别自己再画一个「···」菜单 —— 系统已经有一个了，重复做只会打架。
//
// ── 每个按钮一个独立的玻璃胶囊 ──────────────────────────────────────────
// iOS 26 的规则：**同一条边上相邻的条目会合并成一条玻璃背景**。
// 拆成多个 ToolbarItem 也没用（实测过，照样合并）。
// 要分开得在中间插 `ToolbarSpacer` —— 所以下面每个按钮都跟着一个
// `BarButton`，它做的就是"放一个按钮 + 后面一个分隔"。
//
// 注意 ToolbarSpacer 也占宽度，所以它会让"放不下"来得更早一点 ——
// 这正是上面那个重要性排序要管的事。
//
// ── 为什么用 ToolbarContent 而不是自己画 View ───────────────────────────
// 自己画 = 把"按钮该长什么样"冻结在我写代码的那天。
// 交给 toolbar = 玻璃材质、浮动方式、间距、点击反馈、溢出收纳，
// 全归系统管，跟着 iOS 版本自动更新。
// ============================================================================

import SwiftUI

struct BottomBar: ToolbarContent {

    /// 动作由外面（DiaryListView）传进来。这叫"闭包参数" ——
    /// 相当于把"点了我该干嘛"当参数传，好测试也好复用。
    var onSearch: () -> Void = {}
    var onNew: () -> Void = {}

    /// 待办分类，**顺序即重要性**（越靠左越不容易被收进 ···）
    private let categories = ["待办", "持续", "暂缓", "完成", "全部"]

    var body: some ToolbarContent {

        // 🏠 回首页 —— 排最前。现在已经在首页了，所以暂时什么都不做。
        //BarButton {
        //    Button {} label: { Image(systemName: "house.fill") }   // SF Symbols: 苹果自带图标库
        //}

        // 🔍 搜索
        //
        // `DefaultToolbarItem(kind: .search)` 是 iOS 26 给的系统搜索条目：
        // 平时是一个放大镜按钮，点开才展开成输入框贴着键盘（备忘录那套）。
        //
        // 它必须在 `ToolbarItemGroup` 的外面 —— 它是 ToolbarContent，
        // 而 Group 里只收普通 View，塞进去编译不过。这个限制正好和
        // "每个按钮独立"的写法是同一套。（iOS 17~25 没这个 API，用手画的顶上。）
        if #available(iOS 26.0, *) {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
            ToolbarSpacer(.fixed, placement: .bottomBar)
        } else {
            BarButton {
                Button(action: onSearch) { Image(systemName: "magnifyingglass") }
            }
        }

        // ＋ 新建
        BarButton {
            Button(action: onNew) { Image(systemName: "plus") }
        }

        // 待办分类们，一个按钮一个胶囊
        ForEach(categories, id: \.self) { name in
            BarButton {
                Button(name) { }        // 选中的行为还没做
            }
        }
    }
}

// ────────────────────────────────────────────────────────────────────────────
// 底部条上的一个按钮 = 按钮本体 + 后面跟一个分隔
// ────────────────────────────────────────────────────────────────────────────
// 为什么要包一层：分隔符（ToolbarSpacer）是 **iOS 26 才有的 API**，
// 而我们的最低支持版本是 iOS 17，所以得做版本判断。
// 包一层之后，调用处只写 `BarButton { 任意按钮 }`，不用每个按钮都抄一遍版本判断。
//
// 泛型 `<Label: View>` 就是"这个包装能装任意一种按钮"的意思。
// ────────────────────────────────────────────────────────────────────────────
private struct BarButton<Label: View>: ToolbarContent {

    @ViewBuilder var label: () -> Label

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar, content: label)
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .bottomBar)
        }
    }
}
