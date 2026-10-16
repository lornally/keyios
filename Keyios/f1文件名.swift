import Foundation

/// 把 dog 文件名 (即 root 文本) 缩成列表里显示的名字。
/// 规则来自 mvp.md「每行的文件名缩减」:
///
///     2026-10-11 日记 -> 今天
///     2026-10-10 日记 -> 昨天
///     2026-10-09 日记 -> 前天
///     2026-10-08 日记 -> 08周三      (一周之内)
///     一个月之内      -> 本月X日
///     2个月之内       -> 上月X日
///     一年之内        -> 10-08       (缩掉年份和"日记")
///     所有日记都缩掉"日记"两个字
///
/// 纯函数, 不碰 UI —— 以后挪进 DogKit 或单独测都方便。
enum DiaryNameAbbreviator {

    static func abbreviate(_ fileName: String, today: Date = Date(),
                           calendar: Calendar = .current) -> String {
        // 先摘掉"日记"二字, 剩下日期部分
        let stripped = fileName.replacingOccurrences(of: "日记", with: "")
            .trimmingCharacters(in: .whitespaces)

        guard let date = parseDate(stripped, calendar: calendar) else {
            return stripped          // 认不出日期就原样显示
        }

        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: today)).day ?? 0
        let day = calendar.component(.day, from: date)

        switch days {
        case ..<0:   return full(date)                       // 未来日期(不该出现), 老实显示
        case 0:      return "今天"
        case 1:      return "昨天"
        case 2:      return "前天"
        case 3...6:  return String(format: "%02d周%@", day, weekday(date, calendar))
        default:     break
        }

        let nowYear  = calendar.component(.year, from: today)
        let nowMonth = calendar.component(.month, from: today)
        let y = calendar.component(.year, from: date)
        let m = calendar.component(.month, from: date)

        if y == nowYear, m == nowMonth { return "本月\(day)日" }

        // 上个月 = 今天所在月的上一个月
        let lastMonthEnd = calendar.date(byAdding: .day, value: -1,
                                         to: calendar.date(from: DateComponents(
                                            year: nowYear, month: nowMonth, day: 1))!)!
        if calendar.component(.year, from: lastMonthEnd) == y,
           calendar.component(.month, from: lastMonthEnd) == m { return "上月\(day)日" }

        if y == nowYear { return String(format: "%02d-%02d", m, day) }

        return full(date)                                    // 跨年, 保留年份
    }

    // MARK: - 辅助

    private static let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]

    private static func weekday(_ date: Date, _ calendar: Calendar) -> String {
        weekdayNames[calendar.component(.weekday, from: date) - 1]
    }

    private static func full(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// 认 "2026-10-08" / "26-10-08" 这类开头的日期
    private static func parseDate(_ s: String, calendar: Calendar) -> Date? {
        let parts = s.split(separator: "-", maxSplits: 3).map(String.init)
        guard parts.count >= 3,
              let y = Int(parts[0]), let m = Int(parts[1]), let d = Int(parts[2])
        else { return nil }
        let year = y < 100 ? 2000 + y : y
        return calendar.date(from: DateComponents(year: year, month: m, day: d))
    }
}
