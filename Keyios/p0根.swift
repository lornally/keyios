import SwiftUI

// 启动后的第一屏: 先把日记表从磁盘读出来, 读完再交给列表页。
//
// 为什么要垫这一层: 读盘可能要等 iCloud 下载, 会慢; 列表页只该管"怎么画",
// 不该在 init 里干等。所以读盘放后台, 读完改一下 @State, SwiftUI 自动重画。
struct 根V: View {

  /// nil = 还没读完; 读完后是整张表
  @State private var 表: [String: 日记]?

  /// 读失败时的说明 (找不到目录 / 目录里没有 .dog)
  @State private var 出错: String?

  /// 从后台回到前台时重读一遍 —— 在 Mac 上改了日记, 切回来就能看到
  @Environment(\.scenePhase) private var 场景

  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()

      if let 表 {
        列表v(日记表: 表)
      } else if let 出错 {
        VStack(spacing: 12) {
          Text("读不到日记")
            .font(.headline)
            .foregroundStyle(Theme.primaryText)
          Text(出错)
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .multilineTextAlignment(.center)
        }
        .padding()
      } else {
        ProgressView()
          .tint(Theme.accent)
      }
    }
    .preferredColorScheme(.dark)
    .task { await 装载() }
    .onChange(of: 场景) { _, 新场景 in
      if 新场景 == .active { Task { await 装载() } }
    }
  }

  private func 装载() async {
    // 目录探测和读文件都可能等 iCloud, 整体扔到后台线程。
    // Task.detached 而不是普通 Task: 普通 Task 会继承主线程, 照样卡界面。
    let 结果 = await Task.detached(priority: .userInitiated) { () -> (URL?, [String: 日记]) in
      let 目录 = 日记读取.目录()
      return (目录, 目录 == nil ? [:] : 日记读取.读表())
    }.value

    if let 目录 = 结果.0, 结果.1.isEmpty {
      出错 = "\(目录.path)\n里没有 .dog 文件"
    } else if 结果.0 == nil {
      出错 = "找不到 iCloud 容器 \(日记读取.容器id)。\n真机要先登录 iCloud 并打开 iCloud Drive。"
    } else {
      表 = 结果.1
    }
  }
}
