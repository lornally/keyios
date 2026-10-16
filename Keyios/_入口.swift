// ============================================================================
// 【app 入口】—— 程序从这里开始跑
// ============================================================================
//
// ── 先回答那个问题：是苹果规定要用这个文件名吗？ ──────────────────────────
//
// 不是。苹果**没有**规定文件名，也不规定这个类型叫什么。
// 苹果只要求一件事：整个 app 里有且只有一个 `@main`。
//
// 那为什么大家都叫 xxxApp.swift？因为用 Xcode 新建项目时它默认就这么生成，
// 于是成了社区惯例。我们跟着用，是为了别人（和人自己几年后）一眼能认出来。
// 所以你完全可以把它改名成 `Qidong.swift`，只要 `@main` 还在，照样能跑。
//
// ── 再说这三个套娃：App / Scene / WindowGroup ──────────────────────────────
//
//   App          —— 整个 app（一个进程）。它的 body 声明"这个 app 有哪些场景"。
//   Scene        —— 一个"界面单元"。iPhone 上基本只有一种：WindowGroup。
//   WindowGroup  —— 最常见的场景：装一屏内容。里面放你的第一屏 UI。
//
// 为什么要这么绕？因为 iPad/macOS 上可以多窗口，同一个 App 能开好几个 Scene。
// 手机上用不到这个自由度，但框架是同一套，所以得套这三层。
//
// 类比 Qt：App ≈ QApplication，而 WindowGroup 里那个 View ≈ 主窗口的 centralWidget。
// 区别是 SwiftUI 不"创建窗口然后往里塞控件"，而是**声明一个界面长什么样**，
// 系统负责建窗口、管生命周期、跟着状态重绘。
// ============================================================================

import SwiftUI

// `@main` = "程序入口在这"。等价于 C 的 main()。
// 整个 app 只能有一个。
@main
struct KeyiosApp: App {

    // `some Scene` 里的 `some` 是"我不告诉你具体类型，但肯定是一种 Scene"。
    // Swift 的这套写法叫 opaque return type —— 你不用关心底层类型名，
    // 写起来干净，编译器还能做优化。看到 `some XXX` 就当"返回一个 XXX"读。
    var body: some Scene {

        // WindowGroup 里放的就是第一屏。
        // ── 想改"打开 app 看到什么"，改的就是这一行 ──
        WindowGroup {
            DiaryListView(diaries: sampleDiaries)
        }
        // ↑ `sampleDiaries` 是 Models.swift 里的假数据。
        //   以后接上真实 dog 文件读取，换掉这个参数即可，DiaryListView 本身不用动。
    }
}

// ============================================================================
// 几件可能想知道的事
// ============================================================================
//
// 1. 这里没有"启动时要做点啥"的地方？
//    想加的话：`WindowGroup { ... }.onAppear { ... }` 或者给 DiaryListView 加 .task {}。
//    打开文件、读 iCloud、初始化数据库，以后都放那儿。
//
// 2. 为什么没有 Info.plist？
//    project.yml 里开了 `GENERATE_INFOPLIST_FILE: YES`，Xcode 按构建设置现生成。
//    要加自己的项（比如 iCloud capability），改成在 project.yml 里填。
//
// 3. 界面代码在哪？
//    Keyios/DiaryListView.swift    —— 日记列表页（唯一做完的页）
//    Keyios/DiaryRowView.swift     —— 列表里的"一行"长什么样
//    Keyios/BottomBarView.swift    —— 底部那条浮动按钮栏
//    Keyios/NewNoteView.swift      —— 新建页（占位）
//    Keyios/DiaryDetailView.swift  —— 详情页（占位）
// ============================================================================
