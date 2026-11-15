import Foundation

// ============================================================================
// 【dog 解析】—— .dog 文本 → 详情页的树
// ============================================================================
// 规则: 设计/dog格式细节.md §6; 对照实现: macOS 版
//   f2_dog_io.py / f2_dog_io_block.py / f7_stamp.py (leftup/code)
// 纯函数, 不碰 UI / 磁盘 —— 所以能拿 swiftc 单独编译对拍.
//
// 和 macOS 版的有意差异:
//   * 框词/链接暂不做独立样式, 留在正文里 —— 宁可原样显示, 也不把内容吞掉;
//   * 只拆两类已经有 UI 的修饰符: 时间戳 → 时间(灰字), 图标词 → 图标(小胶囊).
// ============================================================================

enum dog解析 {

  struct 结果: Sendable {
    var 树: [脑图节点]
    /// 文件里行首带 ● 的节点 id —— 打开时默认折叠
    var 折叠: Set<String>
  }

  /// 文本 → 树. 左右子树按显示顺序接成一条 (详情页是顺序列表).
  static func 解析(_ 原文: String) -> 结果 {
    var 文本 = 原文
      .replacingOccurrences(of: "\r\n", with: "\n")
      .replacingOccurrences(of: "\r", with: "\n")
    if 文本.hasPrefix("\u{FEFF}") { 文本.removeFirst() }  // UTF-8 BOM

    // 顺序不能反: 先摘块, 再切区 —— 块内容里可能有区标记.
    let (摘后, 块) = 摘块(文本)
    let 正文 = 去掉尾部区(摘后)
    let (左, 右) = 拆昭(正文)

    var 序号 = 0
    var 折叠: Set<String> = []
    let 左树 = 子树(左, 块: 块, 序号: &序号, 折叠: &折叠)
    let 右树 = 子树(右, 块: 块, 序号: &序号, 折叠: &折叠)
    return 结果(树: 左树 + 右树, 折叠: 折叠)
  }

  // MARK: - 包装块 [[[ ... ]]]: 先整块摘走, 后面的切分就看不到块内容

  /// 行首: 空格缩进 + 可选 ● + 独占一行的 `[` 连跑 (≥3). 返回括号数, 不是块首返回 nil.
  /// 缩进只认空格: tab 缩进的开括号行按普通行处理 (设计 §5).
  private static func 开块(_ 行: String) -> Int? {
    var 正 = Substring(行)
    while 正.first == " " { 正 = 正.dropFirst() }
    if 正.first == "●" { 正 = 正.dropFirst() }
    let 数 = 正.prefix(while: { $0 == "[" }).count
    guard 数 >= 3, 正.count == 数 else { return nil }
    return 数
  }

  /// 全篇摘块: 每个块换成占位符 (缩进/● 留在占位符前面), 内容按占位符记进字典.
  /// 没闭合的块当普通行, 不吞后面的行 (手写文件可能这样).
  private static func 摘块(_ 文本: String) -> (String, [String: String]) {
    let 行们 = 文本.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    var 块: [String: String] = [:]
    var 出: [String] = []
    var i = 0

    while i < 行们.count {
      let 行 = 行们[i]
      guard let 数 = 开块(行) else {
        出.append(行)
        i += 1
        continue
      }

      let 闭 = String(repeating: "]", count: 数)
      var j = i + 1
      while j < 行们.count, 行们[j] != 闭 { j += 1 }
      guard j < 行们.count else {
        出.append(行)  // 没闭合: 当普通行
        i += 1
        continue
      }

      let 占 = "\u{0}\(UUID().uuidString)\u{1}"
      块[占] = 行们[(i + 1)..<j].joined(separator: "\n")
      let 头 = 行[..<行.firstIndex(of: "[")!]
      出.append(String(头) + 占)
      i = j + 1
    }
    return (出.joined(separator: "\n"), 块)
  }

  /// 占位符 → 块内容. 每个占位符全篇只出现一次.
  private static func 填块(_ 文本: String, _ 块: [String: String]) -> String {
    guard !块.isEmpty else { return 文本 }
    var 出 = 文本
    for (占, 内容) in 块 { 出 = 出.replacingOccurrences(of: 占, with: 内容) }
    return 出
  }

  // MARK: - 拆尾部区 / 左右子树

  /// 尾部 `----- 父 -----` 和 `----- 形 -----` 之后都不是正文; 两区先后不定, 取最早的那个.
  private static func 去掉尾部区(_ 文本: String) -> String {
    var 最早: String.Index?
    for 标 in ["----- 父 -----", "----- 形 -----"] {
      if let r = 文本.range(of: 标, options: .backwards),
        (最早 == nil || r.lowerBound < 最早!)
      {
        最早 = r.lowerBound
      }
    }
    return 最早.map { String(文本[..<$0]) } ?? 文本
  }

  /// `----- 昭 -----` 切左右子树; 没有右子树时全部是左子树.
  private static func 拆昭(_ 文本: String) -> (String, String) {
    guard let r = 文本.range(of: "----- 昭 -----") else { return (文本, "") }
    return (String(文本[..<r.lowerBound]), String(文本[r.upperBound...]))
  }

  // MARK: - 缩进 → 树

  /// 每行的层级: 相对缩进推 (标准缩进栈). 空行不占层, 给 0.
  /// tab 当 2 个空格 (设计 §2; 与 f2读日记 的摘要解析一致).
  private static func 层级(_ 行们: [String]) -> [Int] {
    var 栈: [Int] = []
    var 级们: [Int] = []
    for 行 in 行们 {
      if 行.allSatisfy({ $0 == " " || $0 == "\t" }) {
        级们.append(0)
        continue
      }
      let 缩 = 缩进宽(行)
      while let 顶 = 栈.last, 缩 <= 顶 { 栈.removeLast() }
      栈.append(缩)
      级们.append(栈.count - 1)
    }
    return 级们
  }

  private static func 缩进宽(_ 行: String) -> Int {
    var 宽 = 0
    for c in 行 {
      if c == " " {
        宽 += 1
      } else if c == "\t" {
        宽 += 2
      } else {
        break
      }
    }
    return 宽
  }

  /// 一段 (左或右) 文本 → 顶层节点数组. 父栈: 每层最近一个节点在 节点们 里的下标.
  private static func 子树(
    _ 文本: String, 块: [String: String],
    序号: inout Int, 折叠: inout Set<String>
  ) -> [脑图节点] {
    let 行们 = 文本.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    let 级们 = 层级(行们)

    var 节点们: [脑图节点] = []
    var 父们: [Int?] = []
    var 父栈: [Int] = []

    for (行, 级) in zip(行们, 级们) {
      var 正 = Substring(行)
      while 正.first == " " || 正.first == "\t" { 正 = 正.dropFirst() }
      if 正.isEmpty { continue }

      let 折叠标 = 正.first == "●"
      if 折叠标 { 正 = 正.dropFirst() }

      let (时间, 图标, 正文) = 拆两端(填块(String(正), 块))

      let id = "n\(序号)"
      序号 += 1
      if 折叠标 { 折叠.insert(id) }

      let 父: Int? = 级 == 0 ? nil : (级 - 1 < 父栈.count ? 父栈[级 - 1] : nil)
      节点们.append(脑图节点(id: id, 时间: 时间, 正文: 正文, 图标: 图标))
      父们.append(父)
      if 级 < 父栈.count { 父栈.removeSubrange(级...) }
      父栈.append(节点们.count - 1)
    }

    guard !节点们.isEmpty else { return [] }
    // 倒着挂: 轮到父节点时, 它的儿子们已经挂全了 (值类型, 顺序反了会丢子树)
    for i in stride(from: 节点们.count - 1, through: 0, by: -1) {
      if let 父 = 父们[i], 父 < i {
        节点们[父].子.insert(节点们[i], at: 0)
      }
    }
    return 节点们.indices.compactMap { 父们[$0] == nil ? 节点们[$0] : nil }
  }

  // MARK: - 节点文本: 拆出时间戳 / 图标词

  private enum 词类 { case 戳, 框, 图, 链, 文 }

  private struct 词 {
    let 类: 词类
    let 文: String
    let 范围: Range<String.Index>
  }

  /// 时间戳模式 (s9text.时间戳模式): 全量 → 日期 → 时分, 顺序不能换.
  /// 月/日做范围校验, 否则 17_56_00 会被当日期.
  private static let 时间戳模式 =
    "\\d{2}[_-](?:0?[1-9]|1[0-2])[_-](?:0?[1-9]|[12]\\d|3[01])-\\d{1,2}[_:]\\d{1,2}"
    + "|\\d{2}[_-](?:0?[1-9]|1[0-2])[_-](?:0?[1-9]|[12]\\d|3[01])"
    + "|\\d{1,2}[_:]\\d{1,2}"

  /// 修饰符分词: 中括号组 / 时间戳 / 其余按空白和 `_` 切 (RD20 §1: `_` 也是分隔符).
  private static func 分词(_ 文本: String) -> [词] {
    let 模式 = "\\[[^\\[\\]]*\\]|(?:\(时间戳模式))(?=[\\s_]|$)|[^\\s_]+"
    guard let 正则 = try? NSRegularExpression(pattern: 模式) else { return [] }
    let ns = 文本 as NSString
    return 正则.matches(in: 文本, range: NSRange(location: 0, length: ns.length)).compactMap { m in
      guard let r = Range(m.range, in: 文本) else { return nil }
      let tok = String(文本[r])
      return 词(类: 归类(tok), 文: tok, 范围: r)
    }
  }

  private static func 归类(_ tok: String) -> 词类 {
    if 是链接组(tok) || 是链接(tok) { return .链 }
    if 是时间戳(tok) { return .戳 }
    if tok.hasSuffix("框") { return .框 }
    if 图标词.contains(tok) { return .图 }
    return .文
  }

  /// 两端贪心吞修饰符 (修饰符 = 戳/框/图/链, 文是正文).
  /// 返回 (时间, 图标, 正文). 框词和链接不拆走, 留在正文里.
  private static func 拆两端(_ 原文: String) -> (String?, String?, String) {
    let 文本 = 包链接(原文)  // 名字带 `_` 的裸链接先包成中括号, 否则会被当多个 token
    let 词们 = 分词(文本)
    guard !词们.isEmpty else { return (nil, nil, 原文.trimmingCharacters(in: 两端空白)) }

    var 头 = 0
    while 头 < 词们.count, 词们[头].类 != .文 { 头 += 1 }
    var 尾 = 词们.count
    while 尾 > 头, 词们[尾 - 1].类 != .文 { 尾 -= 1 }

    // 时间: 两端修饰符区里的第一个戳; 日期 + 时刻两段 (26-8-9 5:03) 合成一个.
    var 时间位: [Int] = []
    if let k = (0..<头).first(where: { 词们[$0].类 == .戳 }) {
      时间位 = [k]
      if !有时刻(词们[k].文), k + 1 < 头, 词们[k + 1].类 == .戳, 有时刻(词们[k + 1].文) {
        时间位.append(k + 1)
      }
    } else if let k = (尾..<词们.count).first(where: { 词们[$0].类 == .戳 }) {
      时间位 = [k]
    }
    let 时间 = 时间位.isEmpty ? nil : 时间位.map { 格式化(词们[$0].文) }.joined(separator: " ")

    // 图标: 两端修饰符区里的所有图标词, 头在前. 多个用空格隔开, 显示时各画一个胶囊.
    let 图标位 = (0..<头).filter { 词们[$0].类 == .图 } + (尾..<词们.count).filter { 词们[$0].类 == .图 }
    let 图标 = 图标位.isEmpty ? nil : 图标位.map { 词们[$0].文 }.joined(separator: " ")

    // 正文: 原文去掉拆走的戳/图标. 框词、链接原样留着.
    let 去 = Set(时间位 + 图标位)
    var 正文 = 去.isEmpty ? 文本 : 去掉(文本, 词们: 词们, 位: 去)
    正文 = 去链接括号(正文)
    return (时间, 图标, 正文.trimmingCharacters(in: 两端空白))
  }

  /// 删掉指定 token; 顺带吃掉旁边一个分隔符, 免得留下双空格.
  private static func 去掉(_ 文本: String, 词们: [词], 位: Set<Int>) -> String {
    var 范围们: [Range<String.Index>] = []
    for k in 位.sorted() {
      var 起 = 词们[k].范围.lowerBound
      var 止 = 词们[k].范围.upperBound
      if 起 > 文本.startIndex, 是分隔(文本[文本.index(before: 起)]) {
        起 = 文本.index(before: 起)
      } else if 止 < 文本.endIndex, 是分隔(文本[止]) {
        止 = 文本.index(after: 止)
      }
      范围们.append(起..<止)
    }

    // 相邻的两个 token 都拆走时会抢同一个分隔符, 范围会重叠, 先合并.
    var 合: [Range<String.Index>] = []
    for r in 范围们 {
      if let 上 = 合.last, r.lowerBound <= 上.upperBound {
        合[合.count - 1] = 上.lowerBound..<max(上.upperBound, r.upperBound)
      } else {
        合.append(r)
      }
    }

    var 出 = ""
    var 到 = 文本.startIndex
    for r in 合 {
      出 += 文本[到..<r.lowerBound]
      到 = r.upperBound
    }
    出 += 文本[到...]
    return 出
  }

  private static func 是分隔(_ c: Character) -> Bool { c == "_" || c.isWhitespace }

  private static let 两端空白 = CharacterSet(charactersIn: " \t\n\r\u{0B}\u{0C}_")

  // MARK: - 链接 / 时间戳的小零件

  /// 裸链接 token: `xxx.dog`, 不含空白和路径分隔符 (s9text.是链接).
  private static func 是链接(_ tok: String) -> Bool {
    guard tok.hasSuffix(".dog"), tok.count > 4 else { return false }
    return !tok.contains { $0.isWhitespace || $0 == "/" || $0 == "\\" }
  }

  /// 链接组: `[...]` 且最后一个词是链接 (s9text.是链接组). 用户的 `[笔记]` 不算.
  private static func 是链接组(_ tok: String) -> Bool {
    guard tok.hasPrefix("["), tok.hasSuffix("]") else { return false }
    let 内 = tok.dropFirst().dropLast()
    guard let 末 = 内.split(whereSeparator: \.isWhitespace).last else { return false }
    return 是链接(String(末))
  }

  /// 磁盘→内存 (s9text.转内存): 裸链接的名字里含 `_`/空白时包中括号, 保住它是一个 token.
  /// 显示前会由 去链接括号 把中括号摘掉.
  private static func 包链接(_ 文本: String) -> String {
    guard let 正则 = try? NSRegularExpression(pattern: "\\[[^\\[\\]]*\\]|\\S+") else { return 文本 }
    let ns = 文本 as NSString
    var 出 = ""
    var 到 = 0
    for m in 正则.matches(in: 文本, range: NSRange(location: 0, length: ns.length)) {
      let tok = ns.substring(with: m.range)
      let 新: String
      if tok.hasPrefix("["), tok.hasSuffix("]") {
        新 = tok
      } else if 是链接(tok), tok.contains("_") {
        新 = "[\(tok)]"
      } else {
        新 = tok
      }
      出 += ns.substring(with: NSRange(location: 到, length: m.range.location - 到))
      出 += 新
      到 = m.range.location + m.range.length
    }
    出 += ns.substring(from: 到)
    return 出
  }

  /// 显示用: 把链接组的中括号摘掉 (`[牛奶.dog]` → `牛奶.dog`), 用户自己的 `[笔记]` 不动.
  private static func 去链接括号(_ 文本: String) -> String {
    guard let 正则 = try? NSRegularExpression(pattern: "\\[[^\\[\\]]*\\]") else { return 文本 }
    let ns = 文本 as NSString
    var 出 = ""
    var 到 = 0
    for m in 正则.matches(in: 文本, range: NSRange(location: 0, length: ns.length)) {
      let tok = ns.substring(with: m.range)
      出 += ns.substring(with: NSRange(location: 到, length: m.range.location - 到))
      出 += 是链接组(tok) ? String(tok.dropFirst().dropLast()) : tok
      到 = m.range.location + m.range.length
    }
    出 += ns.substring(from: 到)
    return 出
  }

  private static func 是时间戳(_ tok: String) -> Bool {
    guard let 正则 = try? NSRegularExpression(pattern: "^(?:\(时间戳模式))$") else { return false }
    let ns = tok as NSString
    guard let m = 正则.firstMatch(in: tok, range: NSRange(location: 0, length: ns.length)) else {
      return false
    }
    return m.range == NSRange(location: 0, length: ns.length)
  }

  /// 戳里有时刻段. 日期内部的 `_` 不算 (`26_8_9` 是日期, `5_03` 是时分).
  private static func 有时刻(_ 戳: String) -> Bool {
    if 戳.contains(":") { return true }
    guard 戳.contains("_") else { return false }
    return 戳.range(of: "^\\d{2}[_-]\\d{1,2}[_-]\\d{1,2}$", options: .regularExpression) == nil
  }

  /// 灰字展示 (f7_stamp.格式化时间戳): 月日时分补零, `_` 换成 `:`.
  private static func 格式化(_ 戳: String) -> String {
    if let m = 分组匹配(戳, "^(\\d{2})[_-](\\d{1,2})[_-](\\d{1,2})(?:[ -](\\d{1,2})[_:](\\d{1,2}))?$") {
      var 出 = String(format: "%@-%02d-%02d", m[1], Int(m[2])!, Int(m[3])!)
      if m[4] != "", m[5] != "" {
        出 += String(format: " %02d:%02d", Int(m[4])!, Int(m[5])!)
      }
      return 出
    }
    if let m = 分组匹配(戳, "^(\\d{1,2})[_:](\\d{1,2})$") {
      return String(format: "%02d:%02d", Int(m[1])!, Int(m[2])!)
    }
    return 戳
  }

  /// 正则匹配并按捕获组切开; 下标 0 是整串. 匹配不上返回 nil.
  private static func 分组匹配(_ 文本: String, _ 模式: String) -> [String]? {
    guard let 正则 = try? NSRegularExpression(pattern: 模式) else { return nil }
    let ns = 文本 as NSString
    guard let m = 正则.firstMatch(in: 文本, range: NSRange(location: 0, length: ns.length)) else {
      return nil
    }
    return (0..<m.numberOfRanges).map { i in
      let r = m.range(at: i)
      return r.location == NSNotFound ? "" : ns.substring(with: r)
    }
  }

  // MARK: - 图标词表 (macOS 版 s9svgtxt.py 的 svgdic 键名, 不含 SVG 值)

  /// 判定与 macOS 一致: 在表里且不以"框"结尾 = 图标; 以"框"结尾 = 框词 (可点击状态框).
  private static let 图标词: Set<String> = [
    "!!", "##", "%%", "&&", "**", "++", "..", "//", "00", "000", "11", "22",
    "33", "44", "55", "66", "77", "81", "82", "83", "84", "85", "86", "88",
    "99", "<<", "==", ">>", "??", "AI", "OO", "XX", "^^", "__", "adj", "ai",
    "and", "api", "ba", "back", "bb", "book", "bug", "clock", "config", "cr", "day", "db",
    "dd", "dd框", "deploy", "dev", "doc", "done", "done框", "ee", "ee框", "etl", "false", "file",
    "fix", "hifi", "hold", "hold框", "if", "ing", "ing框", "kit", "mod", "note", "now", "ok",
    "oo", "or", "pending", "pending框", "perf", "pipeline", "plan", "plan框", "pp", "prj",
    "refactor", "review",
    "risk", "sa", "security", "test", "think", "todo", "todo框", "true", "tt", "tune", "turn", "up",
    "vv", "xx", "||", "上升", "上线", "与", "业务", "乘", "云长", "人工智能", "代码", "优化",
    "伟人", "伯", "伯伯", "侄", "侄女", "侄子", "值", "假", "兄弟", "关羽", "减", "击杀",
    "击败", "刀剑", "刀叉", "分叉", "分岔", "分析", "分歧", "判断", "判断条件", "剑", "劈叉", "加",
    "加密", "升", "升华", "升空", "升级", "升腾", "升起", "升高", "反", "发布", "发版", "叔",
    "叔伯", "叔叔", "可以微调", "可以改装", "可改", "可调", "叹号", "和", "咦", "商分", "回归", "围棋",
    "圣人", "备注", "外甥", "姑", "姨", "安全", "完成", "完成框", "审查", "家族后代", "对", "对接",
    "小麦", "已办", "已办框", "布尔值", "库", "废弃", "废除", "延后", "延后框", "开发", "待办", "待办框",
    "待定", "待定框", "微调", "思维", "思考", "思路", "性能", "惊叹", "想", "感叹", "成功", "或",
    "战", "战场", "战斗", "战胜", "手册", "抉择", "接口", "提升", "插旗", "插旗框", "操作", "收获",
    "收藏", "改装", "攻击", "数据", "数据库", "数据流", "整理", "文件", "文本", "文档", "斗", "旁系",
    "旁系后代", "旗", "旗子", "旗子框", "旗帜", "旗帜框", "旗框", "日常", "日月", "时钟", "时钟框",
    "时间",
    "星", "星星", "星标", "晋升", "智能", "暂停", "暂停框", "暂存", "暂存框", "暂缓", "暂缓框", "更多",
    "曹操", "未办", "未办框", "未来", "杀", "杀死", "条理", "架构", "核弹", "核爆", "案子", "棋盘",
    "棋谱", "歧路", "死", "毛主席", "毛选", "沙漏", "沙漏框", "注", "注解", "注释", "流水线", "浅析",
    "测试", "深度", "漏斗", "漏斗框", "灯", "灯泡", "灵感", "灵机", "爆", "爆炸", "状态", "现在",
    "疑问", "直系", "直行", "直观", "真", "睡眠", "睡眠框", "碗", "祖先", "神经网络", "秋收", "程序",
    "稻", "稻子", "稻穗", "稻米", "笔记", "笔记本", "等待", "等待框", "等等", "等等框", "管道", "米",
    "粮", "粮食", "系分", "系统", "红宝书", "红旗", "线索", "终局", "终点", "终点框", "结束", "结束框",
    "结构", "编码", "缺陷", "网格", "网络", "联调", "胜", "胜利", "胜局", "脉络", "脑", "脑图",
    "脑子", "脑网", "舅", "舅舅", "苏维埃", "苏联", "虫", "虫子", "表", "表结构", "规划", "规划框",
    "解构", "解析", "解释", "计划", "计划框", "计算", "论", "设想", "设置", "评审", "语录", "说明",
    "调优", "谷", "谷物", "赞叹", "路", "过去", "还有", "进行", "进行中", "进行中框", "进行框", "进阶",
    "选择", "通路", "逻辑", "逻辑运算", "道路", "部署", "配置", "重构", "钩", "错", "问号", "防护",
    "除", "需求", "非", "项目", "风险", "飞升", "飞跃", "餐饮", "饭", "马桶", "骰子", "高粱",
    "麦", "麦子", "麦穗", "齿轮",
  ]
}
