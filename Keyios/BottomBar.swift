// ============================================================================
// 【底部按钮条】—— 用系统的 toolbar，不自己画
// ============================================================================
// 布局从左到右：
//     🏠  ·（待办分类的收拢点） 待办 持续 ＋ 🔍
//
// 见 mvp.md：最优先至少要布置 待办/持续 两个；放不下就用 · 收拢，
// 收拢后 · 里是 全部/待办/持续/暂缓/完成。
//
// ── 为什么是 ToolbarContent 而不是 View ──────────────────────────────────
// 之前我自己画了一条胶囊背景把所有按钮装进去 —— 那是 iOS 18 的样子。
// iOS 26 的做法是**用系统 toolbar**：你只管说"我要一个 home 按钮、一个 + 按钮"，
// 按钮长什么样（玻璃材质）、怎么浮起来、间距多少、点下去什么反馈，全归系统管，
// 而且会跟着 iOS 版本自动更新。
//
// `ToolbarContent` 就是"声明 toolbar 里有哪些条目"的类型（普通 View 是"画什么形状"）。
// 两者不能混：往里塞一个自定义 HStack，系统只会把它当成"一个巨大的条目"，
// 又变回自己画了。
//
// ── 按钮为什么是连成一条的（以及怎么拆开）──────────────────────────────
// iOS 26 的规则：**同一条边上相邻的条目会合并成一条玻璃背景**。
// 拆成 6 个独立 ToolbarItem 也一样会合并（实测过）。
// 要拆开得在中间插 `ToolbarSpacer` —— 实测能拆，但**6 个独立胶囊在一屏里放不下**，
// 系统会把排不下的（＋ 和 🔍）塞进最右边一个 ··· 溢出菜单。
// 对比截图：shots/对比_独立按钮.png（拆开） vs shots/latest.png（合并）。
// 结论：按钮数量多的时候，合并成一条才是对的 —— 苹果自己的 app 里独立按钮多，
// 是因为它们常驻按钮少。
//
// ── 搜索为什么不在这个列表里 ────────────────────────────────────────────
// 因为 iOS 26 有**系统自带的搜索条目**（`DefaultToolbarItem(kind: .search)`）——
// 它平时就是一个放大镜按钮，点开才展开成输入框（系统行为，不用我们写）。
// 自己再放一个 🔍 就会变成两个放大镜。
// ============================================================================

import SwiftUI

struct BottomBar: ToolbarContent {

    /// 动作由外面（DiaryListView）传进来。这叫"闭包参数" ——
    /// 相当于把"点了我该干嘛"当参数传，好测试也好复用。
    var onSearch: () -> Void = {}
    var onNew: () -> Void = {}

    /// 直接铺在条上的分类
    private let pinnedCategories = ["待办", "持续"]
    /// `·` 菜单里的全部选项
    private let allCategories = ["全部", "待办", "持续", "暂缓", "完成"]

    // 所有按钮放同一个 ToolbarItemGroup 里 —— 它们会被系统合并成一条玻璃条。
    // 想拆成独立胶囊，把下面这些拆成一个个 ToolbarItem 再在中间插
    // `ToolbarSpacer(.fixed, placement: .bottomBar)`（iOS 26+，见文件顶部说明）。
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {

            // 🏠 回首页。现在已经在首页了，所以暂时什么都不做。
            //Button {} label: {
            //    Image(systemName: "house.fill")     // SF Symbols：苹果自带的图标库
            //}

            // `·` = 待办分类的收拢点。
            // Menu 是系统控件：点一下弹系统菜单，位置/动画/点外面关闭都是系统管。
            Menu {
                ForEach(allCategories, id: \.self) { name in
                    Button(name) { }        // 选中的行为还没做
                }
            } label: {
                Image(systemName: "ellipsis")
            }

            // 待办 / 持续 —— 两个直接可见的分类
            ForEach(pinnedCategories, id: \.self) { name in
                Button(name) { }            // 选中的行为还没做
            }

            // ＋ 新建
            Button(action: onNew) {
                Image(systemName: "plus")
            }
        }

        // 🔍 搜索：系统的搜索条目。
        // 只能在组的**外面** —— `DefaultToolbarItem` 是 ToolbarContent，
        // 而 ToolbarItemGroup 里只收普通 View，塞进去编译不过。
        // 代价是它会被系统排到这条的最右边（＋ 的右侧）。
        //
        // 只在 iOS 26 及以上存在 —— 我们的最低目标是 iOS 17，老系统上用自己画的顶上。
        if #available(iOS 26.0, *) {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
        } else {
            ToolbarItem(placement: .bottomBar) {
                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}
