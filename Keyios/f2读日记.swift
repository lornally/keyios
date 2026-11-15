import Foundation

// 从磁盘读日记表: 遍历目录 -> 每篇读正文开头的几行 -> 组织成 [文件名: 日记]。
//
// 目录在哪里, 见 `目录()`: 真机走 iCloud 容器; 模拟器直接读 Mac 上的那份,
// 免得开发时非要先给模拟器登录 iCloud。
enum 日记读取 {

  /// 和 macOS 版 Keydog 共用的 iCloud 容器 (见 学习/10.13.技术栈选择.md)。
  /// 双端同一个容器 = 同一份日记。
  static let 容器id = "iCloud.cn.isuyu.keydog"

  /// 日记都放在容器的这个子目录下
  static let 子路径 = "Documents/diary"

  // MARK: - 找目录

  /// 日记目录。找不到返回 nil (没登录 iCloud / 没开 iCloud Drive 时会这样)。
  static func 目录() -> URL? {
    #if targetEnvironment(simulator)
      // 模拟器里 ubiquity 容器要先在模拟器设置里登录 iCloud 才有;
      // 开发时没必要, 因为模拟器进程能直接读宿主机上的 iCloud Drive 目录。
      // (2026-11-14 实测: 能读到 45 个 .dog 文件)
      if let 宿主 = 宿主目录(), FileManager.default.fileExists(atPath: 宿主.path) {
        return 宿主
      }
    #endif

    // 真机: 系统给的 ubiquity 容器。没登录 iCloud 时返回 nil。
    // 这个调用可能卡一下, 别在主线程调它 (所以读表整体放在后台任务里)。
    return FileManager.default.url(forUbiquityContainerIdentifier: 容器id)?
      .appendingPathComponent(子路径)
  }

  #if targetEnvironment(simulator)
    /// 宿主机 iCloud Drive 里对应容器的目录。
    /// 模拟器会注入 SIMULATOR_HOST_HOME=/Users/xxx (实测);
    /// getpwuid 在模拟器里返回 nil, 不能用。
    private static func 宿主目录() -> URL? {
      guard let 家 = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] else {
        return nil
      }
      return URL(fileURLWithPath: 家)
        .appendingPathComponent("Library/Mobile Documents/iCloud~cn~isuyu~keydog")
        .appendingPathComponent(子路径)
    }
  #endif

  // MARK: - 读整张表

  /// 读表过程中发生的事。界面收到一件就改一点, 不用等整张表读完。
  enum 读表事件: Sendable {
    /// 目录列完了: 这些名字可以马上画成一行行空壳 (只有日期, 摘要待填)
    case 名单([String])
    /// 某一篇读完了: 把摘要填进那一行
    case 读到一篇(名: String, 摘要: [String])
  }

  /// 遍历目录, 每个 .dog 整篇读进内存 (日记都很小), 但只取前 3 个一级节点当摘要
  /// —— 解析到第 3 个一级节点就停, 不是文件只读了一半。
  ///
  /// 目录由调用方传进来: `url(forUbiquityContainerIdentifier:)` 在真机第一次
  /// 可能要等好几秒 (iCloud 先要把容器认出来), 一次启动只该问一遍。
  ///
  /// 事件 = 边读边报: 先报名单 (行先摆出来), 再一篇一篇报摘要。
  /// 界面因此像 Apple Notes 一样, 不用等全部读完才有东西看。
  ///
  /// 几十篇是一起读的, 不是一篇一篇排队: 第一次打开时每篇可能都要等 iCloud
  /// 下载, 排队的话几十次等待会相加; 一起发出去, 等的时间能叠在一起。
  static func 读表(
    目录: URL, 事件: (@Sendable (读表事件) -> Void)? = nil
  ) async -> [String: 日记] {
    // .skipsHiddenFiles 顺手排掉 .versions(版本目录)和 .DS_Store
    let 全部 =
      (try? FileManager.default.contentsOfDirectory(
        at: 目录, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) ?? []
    let 文件们 = 全部.filter { $0.pathExtension.lowercased() == "dog" }

    // 名单先给出去: 界面可以先把所有行摆出来, 摘要慢慢填
    事件?(.名单(文件们.map { $0.deletingPathExtension().lastPathComponent }))

    var 表: [String: 日记] = [:]
    表.reserveCapacity(文件们.count)

    // 子任务只负责"读一篇 -> 算摘要"; 往表里放仍在当前任务做, 不用加锁。
    await withTaskGroup(of: (名: String, 摘要: [String]).self) { 组 in
      for 文件 in 文件们 {
        let 名 = 文件.deletingPathExtension().lastPathComponent
        组.addTask {
          // 读不出来(还没从 iCloud 下载下来/编码不对)也照样收录, 摘要空着 ——
          // 不然一篇没下载的日记会从列表里消失, 用户以为丢了。
          let 文本 = try? String(contentsOf: 文件, encoding: .utf8)
          return (名, 文本.map { 摘要($0) } ?? [])
        }
      }

      // 谁先读完谁先报, 所以列表是一行一行填出来的
      for await (名, 摘要) in 组 {
        表[名] = 日记(文件名: 名, 摘要: 摘要)
        事件?(.读到一篇(名: 名, 摘要: 摘要))
      }
    }
    return 表
  }

  // MARK: - 取摘要

  /// 取前 3 个一级节点当摘要。规则见 设计/dog格式细节.md:
  ///   * 缩进用栈推层级: 遇到比当前浅的就退栈, 退到顶就是一级
  ///   * `----- 昭 -----` 是左右子树分隔, 跳过, 栈也要重来
  ///   * `----- 父 -----` / `----- 形 -----` 之后是尾部区, 不是正文, 到此为止
  ///   * 行首 `●` 是折叠标记, 显示时去掉
  ///   * `[[[ ... ]]]` 包装块整体当一个节点, 多行内容先拼成一行
  static func 摘要(_ 文本: String) -> [String] {
    var 结果: [String] = []
    var 栈: [Int] = []  // 当前这条路径上每一层的缩进量
    let 行们 = 文本.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    var i = 0
    while i < 行们.count, 结果.count < 3 {
      let 原行 = 行们[i]
      i += 1

      let 去空 = 原行.trimmingCharacters(in: .whitespaces)
      if 去空.isEmpty { continue }

      if 去空 == "----- 父 -----" || 去空 == "----- 形 -----" { break }
      if 去空 == "----- 昭 -----" {
        栈.removeAll()
        continue
      }

      var 正文 = 去空
      if 正文.hasPrefix("●") { 正文.removeFirst() }
      正文 = 正文.trimmingCharacters(in: .whitespaces)

      // 包装块: 开括号独占一行, 内容到闭括号结束
      if 是括号行(正文, "[") {
        var 块内: [String] = []
        while i < 行们.count {
          let 内行 = 行们[i].trimmingCharacters(in: .whitespaces)
          i += 1
          if 是括号行(内行, "]") { break }
          块内.append(内行)
        }
        正文 = 块内.filter { !$0.isEmpty }.joined(separator: " ")
      }

      if 正文.isEmpty { continue }

      // 缩进栈: 先退到比自己浅的那一层, 自己再入栈
      let 缩进 = 数缩进(原行)
      while let 顶 = 栈.last, 缩进 <= 顶 { 栈.removeLast() }
      let 层级 = 栈.count  // 0 = 一级节点
      栈.append(缩进)

      if 层级 == 0 { 结果.append(正文) }
    }
    return 结果
  }

  /// 这一行是不是至少 3 个连续的开/闭中括号 (包装块的边界行)
  private static func 是括号行(_ 文本: String, _ 括号: Character) -> Bool {
    文本.count >= 3 && 文本.allSatisfy { $0 == 括号 }
  }

  /// 行首缩进量, tab 当 2 个空格 (和落盘规则一致)
  private static func 数缩进(_ 行: String) -> Int {
    var 数 = 0
    for 字符 in 行 {
      if 字符 == " " {
        数 += 1
      } else if 字符 == "\t" {
        数 += 2
      } else {
        break
      }
    }
    return 数
  }
}
