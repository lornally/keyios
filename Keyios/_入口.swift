import SwiftUI  // 为啥要引入? 因为 App / Scene / WindowGroup 这些都是 SwiftUI 给的

@main  // "程序入口在这" —— 整个 app 只能有一个; 文件名无所谓, 苹果只认这个标记
struct KeyiosApp: App {  // App 是个协议(protocol), 这里表示 KeyiosApp 遵守它
  // 这个花括号是结构体的定义体

  var body: some Scene {  // body 是 App 协议要求实现的计算属性, 相当于"必须重写的抽象成员"
    // 这个花括号是计算属性的 getter 方法体, 返回值类型是 some Scene
    // some Scene = "某种 Scene", 具体是哪种不用写出来

    WindowGroup {  // WindowGroup 是 SwiftUI 提供的场景类型, 这里创建它的一个匿名实例
      // 这个花括号是尾随闭包, 也就是 WindowGroup 初始化器的 content 参数

      列表v(日记表: 日记表)  // 闭包里的内容: 第一屏要显示的那个视图
      // 闭包和 body 都只有一条表达式, Swift 允许省略 return, 直接把它当返回值
    }
  }
}

// ============================================================================
// 几件可能想知道的事
// ============================================================================
//
// 1. 这里没有"启动时要做点啥"的地方？
//    想加的话：`WindowGroup { ... }.onAppear { ... }` 或者给 列表v 加 .task {}。
//    打开文件、读 iCloud、初始化数据库，以后都放那儿。
//
// 2. 为什么没有 Info.plist？
//    project.yml 里开了 `GENERATE_INFOPLIST_FILE: YES`，Xcode 按构建设置现生成。
//    要加自己的项（比如 iCloud capability），改成在 project.yml 里填。
//
// 3. 界面代码在哪？（文件名规则：`pN` = 第 N 页, `fN` = 函数, `_` 开头 = 入口）
//    Keyios/p1列表.swift      —— 日记列表页（唯一做完的页）
//    Keyios/p1列表单行.swift  —— 列表里的"一行"长什么样
//    Keyios/p1_底部按钮.swift —— 底部那条浮动按钮栏
//    Keyios/p2脑图.swift      —— 脑图页（占位）
//    Keyios/p3新建.swift      —— 新建页（占位）
//    Keyios/f1文件名.swift    —— 文件名缩减（纯函数，无界面）
//    Keyios/d1日记表.swift    —— 内存数据（日记表字典 + 临时的假数据）
//    Keyios/Theme.swift       —— 配色
// ============================================================================
