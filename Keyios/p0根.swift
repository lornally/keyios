import SwiftUI

// 启动后的第一屏: 先把日记表从磁盘读出来, 读完再交给列表页。
//
// 为什么要垫这一层: 读盘可能要等 iCloud 下载, 会慢; 列表页只该管"怎么画",
// 不该在 init 里干等。所以读盘放后台, 读完改一下 @State, SwiftUI 自动重画。
//
// 为什么第一次打开特别慢 (2026-11-15 的推断):
//   第一次 iCloud 要先认容器, 把这几十个小文件从云端同步到本地, 可能要十几秒;
//   读完文件就落到本地了, 所以第二次打开是毫秒级。慢的不是界面, 是 iCloud。
//   既然等躲不掉, 就把"在等什么"画出来 —— 见下面的 加载页。
struct 根V: View {

  /// 已经读到内存里的日记。不是读完才赋值 —— 名单一到就先摆空行,
  /// 之后读一篇填一行 (见 处理).
  @State private var 表: [String: 日记] = [:]

  /// 读失败时的说明 (找不到目录 / 目录里没有 .dog)
  @State private var 出错: String?

  /// 正在读的时候 .task 和 scenePhase 会同时来, 别叠第二份
  @State private var 是否在装 = false

  /// 从后台回到前台时重读一遍 —— 在 Mac 上改了日记, 切回来就能看到
  @Environment(\.scenePhase) private var 场景

  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()

      if !表.isEmpty {
        列表v(日记表: 表)
      } else if let 出错 {
        出错页(出错)
      } else {
        加载页
      }
    }
    .preferredColorScheme(.dark)
    .task { await 装载() }
    .onChange(of: 场景) { _, 新场景 in
      if 新场景 == .active { Task { await 装载() } }
    }
  }

  // MARK: - 加载页

  /// 目录一列出来就切到列表 (列表自己一行一行长出来), 所以这一页只管
  /// "还没拿到名单"的那段等待 —— 说清在等什么 (正在连接 iCloud…), 别干转圈。
  private var 加载页: some View {
    VStack(spacing: 18) {
      Text("Keyios")
        .font(.system(size: 32, weight: .semibold))
        .foregroundStyle(Theme.accent)

      ProgressView()
        .controlSize(.large)
        .tint(Theme.accent)

      Text("正在连接 iCloud…")
        .font(.footnote)
        .foregroundStyle(Theme.secondaryText)
    }
    .padding(.horizontal, 40)
  }

  // MARK: - 出错页

  private func 出错页(_ 说明: String) -> some View {
    VStack(spacing: 12) {
      Text("读不到日记")
        .font(.headline)
        .foregroundStyle(Theme.primaryText)
      Text(说明)
        .font(.footnote)
        .foregroundStyle(Theme.secondaryText)
        .multilineTextAlignment(.center)
    }
    .padding()
  }

  // MARK: - 读盘

  private func 装载() async {
    guard !是否在装 else { return }  // 启动时 .task 和 scenePhase 会同时触发
    是否在装 = true
    defer { 是否在装 = false }

    // 目录探测和读文件都可能等 iCloud, 都扔到后台线程。
    // Task.detached 而不是普通 Task: 普通 Task 会继承主线程, 照样卡界面。
    let 目录 = await Task.detached(priority: .userInitiated) {
      // 目录只问一次 —— url(forUbiquityContainerIdentifier:) 第一次会很慢
      日记读取.目录()
    }.value

    guard let 目录 else {
      出错 = "找不到 iCloud 容器 \(日记读取.容器id)。\n真机要先登录 iCloud 并打开 iCloud Drive。"
      return
    }

    // 边读边报: 名单先到 -> 列表先摆出所有行; 之后读一篇填一行, 不等全部读完
    let 结果 = await Task.detached(priority: .userInitiated) { () -> [String: 日记] in
      await 日记读取.读表(目录: 目录) { 事件 in
        // 回调在后台线程, 改界面要回主线程
        Task { @MainActor in 处理(事件) }
      }
    }.value

    if 结果.isEmpty {
      出错 = "\(目录.path)\n里没有 .dog 文件"
    } else {
      出错 = nil
      表 = 结果  // 收尾对齐: 把已经不在磁盘上的行去掉
    }
  }

  /// 把读表过程中的事件落到界面上
  private func 处理(_ 事件: 日记读取.读表事件) {
    switch 事件 {
    case .名单(let 项们):
      // 先把行摆出来 (摘要空着), 像 Apple Notes: 有标题先看, 内容慢慢填
      for 项 in 项们 where 表[项.名] == nil {
        表[项.名] = 日记(文件名: 项.名, 摘要: [], 修改日: 项.修改日)
      }
    case .读到一篇(let 名, let 摘要, let 修改日):
      表[名] = 日记(文件名: 名, 摘要: 摘要, 修改日: 修改日)
    }
  }
}
