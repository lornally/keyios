// ============================================================================
// 【日记详情页】—— 两种树样式 + 文字同丛色
// ============================================================================
// 视觉基准: 设计/demo/详情页-树样式对比-v2.html
//   左轴: 一级沿左侧轴排, 儿子右下缩进, 每行底线拉到右边缘, 折角圆角
//   列表: 圆点数量 = 层级, 一级一个大点, 同丛一色
// 数据: 按文件名从 iCloud 目录现读同名 .dog, 由 f3解析dog 解析成树。
// ============================================================================

import SwiftUI

struct 脑图V: View {

  /// 点的是哪一篇 —— 标题用文件名, 正文按同名 .dog 从磁盘现读
  let 日记: 日记

  // ── 状态 ──
  @State private var 树: [脑图节点] = []
  @State private var 折叠中: Set<String> = []
  /// 首次解析的结果: "重置"就是回到它 (编辑还没落盘, 磁盘内容不变)
  @State private var 原始: dog解析.结果?
  @State private var 加载: 载入状态 = .加载中
  @State private var 样式: 树样式 = .左轴
  @State private var 文字同色 = false
  @State private var 编辑中 = false
  @State private var 待聚焦: String?
  /// 进编辑态时各节点的正文: 提交时如果被清空, 用它还原
  @State private var 编辑快照: [String: String] = [:]
  @FocusState private var 焦点: String?

  private enum 载入状态: Equatable {
    case 加载中
    case 失败(String)
    case 完成
  }

  var body: some View {
    ZStack {
      Theme.background.ignoresSafeArea()

      switch 加载 {
      case .加载中:
        ProgressView()
          .tint(Theme.accent)

      case .失败(let 说明):
        VStack(spacing: 10) {
          Text("读不到日记")
            .font(.headline)
            .foregroundStyle(Theme.primaryText)
          Text(说明)
            .font(.footnote)
            .foregroundStyle(Theme.secondaryText)
            .multilineTextAlignment(.center)
        }
        .padding(24)

      case .完成:
        ScrollView {
          Group {
            if 样式 == .左轴 {
              轴树
            } else {
              列表树
            }
          }
          .padding(.horizontal, 14)
          .padding(.top, 6)
          .padding(.bottom, 38)
        }
      }
    }
    // 编辑时收起控制条, 把屏幕让给键盘和正文
    .safeAreaInset(edge: .bottom, spacing: 0) {
      if !编辑中, 加载 == .完成 { 控制条 }
    }
    .navigationTitle(日记名f.缩写(日记.文件名))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button(编辑中 ? "完成" : "编辑") {
          if 编辑中 { 完成编辑() } else { 开始编辑() }
        }
      }
    }
    .tint(Theme.accent)
    .task { await 装载() }
    .preferredColorScheme(.dark)
  }

  // MARK: - 展平: 折叠状态 + 层级 + 丛色

  /// 当前要显示的行(先序遍历, 折叠的后代不出现)。
  /// 两种样式吃同一份, 所以切换样式时折叠状态不会丢。
  private var 行们: [行项] {
    var 结果: [行项] = []
    for (序, 节点) in 树.enumerated() {
      展开(节点, 层: 0, 色: 色板[序 % 色板.count], 出: &结果)
    }
    return 结果
  }

  private func 展开(_ 节点: 脑图节点, 层: Int, 色: Color, 出: inout [行项]) {
    出.append(行项(节点: 节点, 层: 层, 色: 色))
    guard !折叠中.contains(节点.id) else { return }
    for 子 in 节点.子 {
      展开(子, 层: 层 + 1, 色: 色, 出: &出)
    }
  }

  // MARK: - 方案 1: 左轴树

  private var 轴树: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(行们) { 行 in
        轴行(行, 首行: 行.id == 行们.first?.id)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .coordinateSpace(name: "树")
    .overlayPreferenceValue(脑图锚点键.self) { 锚点 in
      连线层(行们: 行们, 锚点: 锚点)
        .allowsHitTesting(false)  // 线只是画的, 别挡点击
    }
  }

  private func 轴行(_ 行: 行项, 首行: Bool) -> some View {
    内容(行)
      .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
      // 量的是"正文盒"的左边缘和底(底线画在底下方 4pt)
      .background {
        GeometryReader { geo in
          let 框 = geo.frame(in: .named("树"))
          Color.clear.preference(
            key: 脑图锚点键.self,
            value: [行.id: 脑图锚点(左: 框.minX, 底: 框.maxY + 4)])
        }
      }
      .padding(.leading, 24 + CGFloat(行.层) * 24)  // 每层右移 24
      .padding(.trailing, 8)
      .padding(.top, 5)
      .padding(.bottom, 8)
      .padding(.top, 行.层 == 0 && !首行 ? 16 : 0)  // 两丛之间留空
      .frame(maxWidth: .infinity, alignment: .leading)
      // 折叠热区: 行首 22pt 宽的隐形竖条, 一级正好盖住圆点
      .overlay(alignment: .leading) {
        if 行.节点.有子 {
          Color.clear
            .frame(width: 22)
            .contentShape(Rectangle())
            .offset(x: CGFloat(行.层) * 24)
            .onTapGesture { 切换折叠(行.节点) }
        }
      }
  }

  // MARK: - 方案 2: 列表 + 圆点阶梯

  private var 列表树: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(行们) { 行 in
        列表行(行, 首行: 行.id == 行们.first?.id)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func 列表行(_ 行: 行项, 首行: Bool) -> some View {
    HStack(alignment: .top, spacing: 10) {
      标记区(行)
      内容(行)
        .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
    }
    .padding(.leading, 4)
    .padding(.trailing, 8)
    .padding(.vertical, 5)
    .padding(.top, 行.层 == 0 && !首行 ? 16 : 0)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func 标记区(_ 行: 行项) -> some View {
    let 点径: [CGFloat] = [11, 8.5, 7, 6, 5]
    let 径 = 点径[min(行.层, 点径.count - 1)]
    return HStack(spacing: 5) {
      ForEach(0...行.层, id: \.self) { _ in
        Circle().fill(行.色).frame(width: 径, height: 径)
      }
    }
    .frame(height: 26)
    .contentShape(Rectangle())
    .onTapGesture { 切换折叠(行.节点) }
  }

  // MARK: - 两种样式共用的一行

  @ViewBuilder
  private func 内容(_ 行: 行项) -> some View {
    if 编辑中 {
      编辑内容(行)
    } else {
      显示内容(行)
        .onTapGesture(count: 2) { 开始编辑(行.id) }
    }
  }

  private func 显示内容(_ 行: 行项) -> some View {
    let 顶层 = 行.层 == 0
    let 正 = Text(行.节点.正文)
      .font(顶层 ? .headline : .body)  // 17pt: 顶层加粗, 正文常规
      .foregroundStyle(正文颜色(行))

    return HStack(alignment: .firstTextBaseline, spacing: 0) {
      // 时间只做前缀, 和正文拼成同一段文字 —— 折行才会从内容左边对齐
      if let 时间 = 行.节点.时间 {
        (Text(时间 + "  ")
          .font(.footnote)  // 13pt
          .monospacedDigit()
          .foregroundStyle(时间颜色(行)) + 正)
          .lineSpacing(7)
      } else {
        正.lineSpacing(7)
      }
      if let 图标 = 行.节点.图标 {
        // 一行可以有多个图标词 (盘上空格隔开), 各画一个小胶囊
        ForEach(Array(图标.split(separator: " ").enumerated()), id: \.offset) { _, 词 in
          图标徽(String(词), 色: 行.色)
        }
      }
      if 行.节点.有子, 折叠中.contains(行.id) {
        折叠徽(行)
      }
    }
  }

  private func 编辑内容(_ 行: 行项) -> some View {
    let 顶层 = 行.层 == 0
    return HStack(alignment: .firstTextBaseline, spacing: 0) {
      if let 时间 = 行.节点.时间 {
        Text(时间 + "  ")
          .font(.footnote)  // 13pt
          .monospacedDigit()
          .foregroundStyle(时间颜色(行))
      }
      TextField("", text: 正文绑定(行.id), axis: .vertical)
        .textFieldStyle(.plain)
        .font(顶层 ? .headline : .body)  // 和显示态一致
        .foregroundStyle(正文颜色(行))
        .focused($焦点, equals: 行.id)
        .onSubmit { 焦点 = nil }
        .onAppear {
          guard 待聚焦 == 行.id else { return }
          待聚焦 = nil
          DispatchQueue.main.async { 焦点 = 行.id }
        }
      // 编辑时 TextField 会吃掉整行宽度, 徽章贴不到文字尾巴上, 先不显示
    }
  }

  private func 图标徽(_ 文本: String, 色: Color) -> some View {
    let (背景, 字色) = 图标配色(色)
    return Text(文本)
      .font(.system(size: 10, weight: .semibold))
      .tracking(0.5)
      .foregroundStyle(字色)
      .padding(.horizontal, 5)
      .padding(.vertical, 1.5)
      .background(RoundedRectangle(cornerRadius: 4.5).fill(背景))
      .padding(.leading, 6)
      .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
  }

  private func 折叠徽(_ 行: 行项) -> some View {
    Button { 切换折叠(行.节点) } label: {
      Text("+\(行.节点.后代数)")
        .font(.system(size: 10.5, weight: .semibold))
        .foregroundStyle(行.色)
        .padding(.horizontal, 6)
        .padding(.vertical, 1)
        .background(Capsule().fill(行.色.opacity(0.14)))
    }
    .buttonStyle(.plain)
    .padding(.leading, 6)
    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 3 }
  }

  // ── 颜色: 同色开关只换文字/时间/图标, 不换圆点和线 ──
  private func 正文颜色(_ 行: 行项) -> Color {
    if 文字同色 { return 行.色 }
    return 行.层 == 0 ? .white : 正文灰白
  }

  private func 时间颜色(_ 行: 行项) -> Color {
    文字同色 ? 行.色.混(时间灰, 0.45) : 时间灰
  }

  private func 图标配色(_ 色: Color) -> (背景: Color, 字色: Color) {
    文字同色
      ? (色.opacity(0.12), 色.混(.white, 0.22))
      : (Color.white.opacity(0.08), 图标灰)
  }

  // MARK: - 折叠 / 编辑

  private func 切换折叠(_ 节点: 脑图节点) {
    guard 节点.有子 else { return }
    if 折叠中.contains(节点.id) {
      折叠中.remove(节点.id)
    } else {
      折叠中.insert(节点.id)
    }
    if 待聚焦 == 节点.id { 待聚焦 = nil }
  }

  private func 开始编辑(_ 节点id: String? = nil) {
    if 编辑快照.isEmpty {
      编辑快照 = 全部正文(树)
    }
    待聚焦 = 节点id
    编辑中 = true
  }

  private func 完成编辑() {
    焦点 = nil
    整理正文(&树)
    待聚焦 = nil
    编辑中 = false
    编辑快照 = [:]
  }

  /// 落盘前的那点整理搬到提交时: 去首尾空白; 清空了的还原成编辑前
  private func 整理正文(_ 列表: inout [脑图节点]) {
    for i in 列表.indices {
      let 新 = 列表[i].正文.trimmingCharacters(in: .whitespacesAndNewlines)
      if 新.isEmpty {
        列表[i].正文 = 编辑快照[列表[i].id] ?? 列表[i].正文
      } else {
        列表[i].正文 = 新
      }
      整理正文(&列表[i].子)
    }
  }

  private func 全部正文(_ 列表: [脑图节点]) -> [String: String] {
    var 结果: [String: String] = [:]
    func 收(_ 列: [脑图节点]) {
      for 节点 in 列 {
        结果[节点.id] = 节点.正文
        收(节点.子)
      }
    }
    收(列表)
    return 结果
  }

  private func 正文绑定(_ id: String) -> Binding<String> {
    Binding(
      get: { 取正文(id, 在: 树) ?? "" },
      set: { 新 in 设正文(id, 新, 在: &树) })
  }

  private func 取正文(_ id: String, 在 列表: [脑图节点]) -> String? {
    for 节点 in 列表 {
      if 节点.id == id { return 节点.正文 }
      if let 找 = 取正文(id, 在: 节点.子) { return 找 }
    }
    return nil
  }

  private func 设正文(_ id: String, _ 新: String, 在 列表: inout [脑图节点]) {
    for i in 列表.indices {
      if 列表[i].id == id {
        列表[i].正文 = 新
        return
      }
      设正文(id, 新, 在: &列表[i].子)
    }
  }

  private func 全部收起() {
    var 集: Set<String> = []
    func 收(_ 列: [脑图节点]) {
      for 节点 in 列 where 节点.有子 {
        集.insert(节点.id)
        收(节点.子)
      }
    }
    收(树)
    折叠中 = 集
  }

  private func 重置() {
    guard let 原始 else { return }
    应用(原始)
  }

  // MARK: - 从磁盘装载

  /// 目录探测和读文件都可能等 iCloud, 整体扔到后台线程 (和 根V 同一套路).
  private func 装载() async {
    let 名 = 日记.文件名
    let 结果 = await Task.detached(priority: .userInitiated) {
      () -> (值: dog解析.结果?, 错: String?) in
      guard let 目录 = 日记读取.目录() else {
        return (nil, "找不到 iCloud 日记目录。\n真机要先登录 iCloud 并打开 iCloud Drive。")
      }
      let 文件 = 目录.appendingPathComponent(名 + ".dog")
      guard let 文本 = try? String(contentsOf: 文件, encoding: .utf8) else {
        return (nil, "读不到 \(文件.lastPathComponent)。\n可能还没从 iCloud 下载下来。")
      }
      return (dog解析.解析(文本), nil)
    }.value

    if let 值 = 结果.值 {
      原始 = 值
      应用(值)
      加载 = .完成
    } else {
      加载 = .失败(结果.错 ?? "未知错误")
    }
  }

  /// 把一份解析结果铺到界面上 —— 首次装载和"重置"共用
  private func 应用(_ 值: dog解析.结果) {
    焦点 = nil
    树 = 值.树
    折叠中 = 值.折叠
    待聚焦 = nil
    编辑中 = false
    编辑快照 = [:]
  }

  // MARK: - 底部控制条

  private var 控制条: some View {
    HStack(spacing: 8) {
      styleSwitch

      Button {
        文字同色.toggle()
      } label: {
        小胶囊("同色", 选中: 文字同色)
      }
      .buttonStyle(.plain)

      Menu {
        Button("全部展开") { 折叠中 = [] }
        Button("全部收起") { 全部收起() }
        Button("重置", role: .destructive) { 重置() }
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.white.opacity(0.65))
          .frame(width: 34, height: 26)
          .background(Capsule().fill(Color.white.opacity(0.06)))
      }
    }
    .padding(5)
    .background(Capsule().fill(Theme.barBackground))
    .padding(.horizontal, 14)
    .padding(.bottom, 6)
  }

  private var styleSwitch: some View {
    HStack(spacing: 2) {
      ForEach(树样式.allCases) { 项 in
        Button {
          样式 = 项
        } label: {
          小胶囊(项.名称, 选中: 样式 == 项)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func 小胶囊(_ 名称: String, 选中: Bool) -> some View {
    Text(名称)
      .font(.system(size: 13, weight: .medium))
      .foregroundStyle(选中 ? Theme.accent : Color.white.opacity(0.55))
      .padding(.horizontal, 12)
      .frame(height: 26)
      .background(Capsule().fill(选中 ? Theme.accent.opacity(0.15) : .clear))
  }
}

// MARK: - 两种样式共用的行数据

private enum 树样式: CaseIterable, Identifiable {
  case 左轴
  case 列表

  var id: Self { self }
  var 名称: String { self == .左轴 ? "左轴" : "列表" }
}

private struct 行项: Identifiable {
  let 节点: 脑图节点
  let 层: Int
  let 色: Color

  var id: String { 节点.id }
}

// MARK: - 左轴的线: 量好每行位置, 在 Canvas 里画

private struct 脑图锚点: Equatable {
  var 左: CGFloat  // 正文盒左边缘
  var 底: CGFloat  // 底线 y
}

private struct 脑图锚点键: PreferenceKey {
  static var defaultValue: [String: 脑图锚点] { [:] }
  static func reduce(value: inout [String: 脑图锚点], nextValue: () -> [String: 脑图锚点]) {
    value.merge(nextValue()) { _, 新 in 新 }
  }
}

private struct 连线层: View {
  let 行们: [行项]
  let 锚点: [String: 脑图锚点]

  private let 左轴 = 12.0  // 一级节点的竖轴 x
  private let 圆角 = 7.0

  var body: some View {
    Canvas { 画布, 尺寸 in
      let 一级们 = 行们.filter { $0.层 == 0 }

      // 左轴: 从第一个一级到底线最后一个一级
      if let 首 = 一级们.first.flatMap({ 锚点[$0.id] }),
        let 尾 = 一级们.last.flatMap({ 锚点[$0.id] }),
        一级们.count > 1
      {
        var 轴 = Path()
        轴.move(to: CGPoint(x: 左轴, y: 首.底))
        轴.addLine(to: CGPoint(x: 左轴, y: 尾.底))
        画布.stroke(轴, with: .color(.white.opacity(0.16)), lineWidth: 1)
      }

      // 一级行的底线: 从轴一路拉到右边缘, 圆点在交点收口
      for 行 in 一级们 {
        guard let 点 = 锚点[行.id] else { continue }
        var 线 = Path()
        线.move(to: CGPoint(x: 左轴, y: 点.底))
        线.addLine(to: CGPoint(x: 尺寸.width, y: 点.底))
        画布.stroke(线, with: .color(行.色.opacity(0.62)), lineWidth: 1.4)
      }

      // 父子: 主干 + 每个儿子一个圆角拐弯, 横线当该行的底线
      let 子索引 = 儿子索引()
      for (父序, 子们) in 子索引 {
        guard let 最后 = 子们.last,
          let 父点 = 锚点[行们[父序].id],
          let 末点 = 锚点[行们[最后].id]
        else { continue }

        let 干 = 父点.左 + 12  // 主干在儿子正文左边 12pt
        var 主干 = Path()
        主干.move(to: CGPoint(x: 干, y: 父点.底))
        // 止于最后一个儿子圆角的起点, 不在角里多出一截
        主干.addLine(to: CGPoint(x: 干, y: 末点.底 - 圆角))
        画布.stroke(主干, with: .color(行们[父序].色.opacity(0.62)), lineWidth: 1.4)

        for 子序 in 子们 {
          guard let 子点 = 锚点[行们[子序].id] else { continue }
          var 拐 = Path()
          拐.move(to: CGPoint(x: 干, y: 子点.底 - 圆角))
          拐.addQuadCurve(
            to: CGPoint(x: 干 + 圆角, y: 子点.底),
            control: CGPoint(x: 干, y: 子点.底))
          拐.addLine(to: CGPoint(x: 尺寸.width, y: 子点.底))
          画布.stroke(拐, with: .color(行们[子序].色.opacity(0.62)), lineWidth: 1.4)
        }
      }

      // 一级圆点最后画, 压在线的交点上
      for 行 in 一级们 {
        guard let 点 = 锚点[行.id] else { continue }
        let 圈 = CGRect(x: 左轴 - 5, y: 点.底 - 5, width: 10, height: 10)
        画布.fill(Path(ellipseIn: 圈), with: .color(行.色))
      }
    }
  }

  /// 先序遍历里, 每个节点的可见儿子下标。缩进栈: 弹到比自己浅的, 就是爹。
  private func 儿子索引() -> [Int: [Int]] {
    var 结果: [Int: [Int]] = [:]
    var 栈: [Int] = []
    for (序, 行) in 行们.enumerated() {
      while let 上 = 栈.last, 行们[上].层 >= 行.层 {
        栈.removeLast()
      }
      if let 父 = 栈.last {
        结果[父, default: []].append(序)
      }
      栈.append(序)
    }
    return 结果
  }
}

// MARK: - 配色

private let 色板: [Color] = [
  Color(hex: "#FFEAA7"),
  Color(hex: "#A8D8C9"),
  Color(hex: "#A9C7FF"),
  Color(hex: "#F3B7C6"),
  Color(hex: "#F6C28B"),
  Color(hex: "#C9B6FF"),
]

private let 正文灰白 = Color(hex: "#EDEDF0")
private let 时间灰 = Color(hex: "#8C8C92")
private let 图标灰 = Color(hex: "#BDBDC3")

// SwiftUI 没有现成的两色混合, 同色模式下时间/图标要按比例调。
private extension Color {
  /// t = 0 是自己, t = 1 是另一个
  func 混(_ 另: Color, _ t: Double) -> Color {
    let 甲 = UIColor(self).分量
    let 乙 = UIColor(另).分量
    return Color(
      red: 甲.r + (乙.r - 甲.r) * t,
      green: 甲.g + (乙.g - 甲.g) * t,
      blue: 甲.b + (乙.b - 甲.b) * t)
  }
}

private extension UIColor {
  var 分量: (r: Double, g: Double, b: Double) {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Double(r), Double(g), Double(b))
  }
}

// 这一页的 #Preview 去掉了: 内容现在要从 iCloud 目录读, 预览里没有那份文件.
// 想看布局跑真机/模拟器 (模拟器会走 日记读取 的宿主机目录回退).
