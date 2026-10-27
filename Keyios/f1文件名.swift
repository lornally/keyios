import Foundation

/// 把 dog 文件名 (磁盘形态, 如 "26-10-11_日记"; 内存形态 "2026-10-11 日记" 也认)
/// 缩成列表里显示的名字。规则来自 设计/mvp.md「每行的文件名缩减」:
///
///     26-10-11_日记 -> 今天
///     26-10-10_日记 -> 昨天
///     26-10-09_日记 -> 前天
///     26-10-08_日记 -> 08周三      (一周之内)
///     一个月之内     -> 本月X日
///     2个月之内      -> 上月X日
///     一年之内       -> 10-08      (缩掉年份和"日记")
///     所有日记都缩掉"日记"两个字
///
/// 纯函数, 不碰 UI —— 以后挪进 DogKit 或单独测都方便。
enum 日记名f {
  //static方法是为了 日记名f.缩写("26-10-11_日记") 这种写法, 不用先 new 一个实例。
  static func 缩写(
    _ fileName: String, today: Date = Date(),
    calendar: Calendar = .current
  ) -> String {
    guard let date = 日期(fileName, calendar: calendar) else {
      return 干净名(fileName)  // 没有日期(比如 "摩托车")就显示干净的名字
    }

    let days =
      calendar.dateComponents(
        [.day], from: calendar.startOfDay(for: date),
        to: calendar.startOfDay(for: today)
      ).day ?? 0
    let day = calendar.component(.day, from: date)

    switch days {
    case ..<0: return full(date)  // 未来日期(不该出现), 老实显示
    case 0: return "今天"
    case 1: return "昨天"
    case 2: return "前天"
    case 3...6: return String(format: "%02d周%@", day, weekday(date, calendar))
    default: break
    }

    let nowYear = calendar.component(.year, from: today)
    let nowMonth = calendar.component(.month, from: today)
    let y = calendar.component(.year, from: date)
    let m = calendar.component(.month, from: date)

    if y == nowYear, m == nowMonth { return "本月\(day)日" }

    // 上个月 = 今天所在月的上一个月
    let lastMonthEnd = calendar.date(
      byAdding: .day, value: -1,
      to: calendar.date(
        from: DateComponents(
          year: nowYear, month: nowMonth, day: 1))!)!
    if calendar.component(.year, from: lastMonthEnd) == y,
      calendar.component(.month, from: lastMonthEnd) == m
    {
      return "上月\(day)日"
    }

    if y == nowYear { return String(format: "%02d-%02d", m, day) }

    return full(date)  // 跨年, 保留年份
  }

  // MARK: - 辅助

  /// 从文件名里解出日期: "26-10-16_日记" -> 2026-10-16; 解不出返回 nil (比如 "摩托车")。
  /// 列表页排序也用它 (见 p1列表.swift)。
  static func 日期(_ fileName: String, calendar: Calendar = .current) -> Date? {
    let parts = 干净名(fileName).split(separator: "-").map(String.init)
    guard parts.count >= 3,
      let y = Int(parts[0]), let m = Int(parts[1]),
      // 日后面可能还粘着下划线("16_")或后缀(".dog"), 只取开头的数字
      let d = Int(parts[2].prefix(while: \.isNumber))
    else { return nil }
    let year = y < 100 ? 2000 + y : y
    return calendar.date(from: DateComponents(year: year, month: m, day: d))
  }

  /// 摘掉"日记"二字和磁盘上的连接符(下划线/点), 剩下的就是干净的名字
  private static func 干净名(_ fileName: String) -> String {
    fileName.replacingOccurrences(of: "日记", with: "")
      .trimmingCharacters(in: CharacterSet(charactersIn: " _."))
  }

  private static let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]

  private static func weekday(_ date: Date, _ calendar: Calendar) -> String {
    weekdayNames[calendar.component(.weekday, from: date) - 1]
  }

  private static func full(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
  }
}
