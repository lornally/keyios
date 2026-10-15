// ============================================================================
// 【底部浮动按钮条】—— 这是你自己写的那个，不是系统控件
// ============================================================================
// 位置：Keyios/BottomBarView.swift（本文件）
//
// 布局从左到右：
//     🏠  home(图标)
//     ·   待办分类的"收拢点"，点开是菜单
//     待办 持续   直接铺在外面的两个最常用分类
//     🔍  搜索
//     +   新建
//
// 见 mvp.md：最优先至少要布置 待办/持续 两个；放不下就用 · 收拢，
// 收拢后 · 里是 全部/待办/持续/暂缓/完成。
//
// 【怎么体验】模拟器窗口是能点的。跑起 app 后直接在模拟器里点这些按钮。
// ============================================================================

import SwiftUI

struct BottomBarView: View {

    // 两个按钮的动作由外面（DiaryListView）传进来。
    // 这叫"闭包参数"—— 相当于把"点了我该干嘛"作为参数传进来，
    // 好处是这个 View 不需要知道外面怎么实现，好测试也好复用。
    var onSearch: () -> Void = {}
    var onNew: () -> Void = {}

    /// 直接铺在条上的分类
    private let pinnedCategories = ["待办", "持续"]
    /// `·` 菜单里的全部选项
    private let allCategories = ["全部", "待办", "持续", "暂缓", "完成"]

    var body: some View {
        HStack(spacing: 12) {

            // 🏠 回首页。现在已经在首页了，所以暂时什么都不做。
            Button {} label: {
                Image(systemName: "house.fill")        // SF Symbols：苹果自带的图标库
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.accent)
            }

            // `·` = 待办分类的收拢点。
            // Menu 是系统控件：点一下弹出系统菜单，位置/动画/点外面关闭都是系统管。
            Menu {
                ForEach(allCategories, id: \.self) { name in
                    Button(name) { }        // 选中的行为还没做
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 30, height: 30)
                    .background(Circle().stroke(Theme.primaryText.opacity(0.35)))
            }

            // 待办 / 持续 —— 两个直接可见的分类
            ForEach(pinnedCategories, id: \.self) { name in
                Button {} label: {
                    Text(name)
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().stroke(Theme.accent))
                }
            }

            Spacer(minLength: 0)    // 把后面两个按钮顶到右边

            // 🔍 搜索 -> 让列表页把搜索框显示出来
            Button(action: onSearch) {
                Image(systemName: "magnifyingglass").font(.system(size: 19))
            }

            // + 新建 -> 让列表页弹出新建页
            Button(action: onNew) {
                Image(systemName: "plus").font(.system(size: 21))
            }
        }
        .foregroundStyle(Theme.primaryText)
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Capsule().fill(Theme.barBackground))   // 圆角胶囊底
        .padding(.horizontal, 12)
    }
}

// ────────────────────────────────────────────────────────────────────────────
// #Preview：不是 app 会跑的代码，只是给编辑器/预览工具"单独画这一屏"用。
// 这里把它摆在屏幕最底下，模拟它在真实页面里的位置。
// （完整说明见 DiaryListView.swift 末尾）
// ────────────────────────────────────────────────────────────────────────────
#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        VStack { Spacer(); BottomBarView() }
    }
    .preferredColorScheme(.dark)
}
