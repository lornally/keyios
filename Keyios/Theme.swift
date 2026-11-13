// ============================================================================
// 【全局配色】
// ============================================================================
// 改颜色只改这一个文件，整个 app 跟着变。
// ============================================================================

import SwiftUI

// 主题
enum Theme {

  /// 背景：纯黑
  static let background = Color.black

  /// 主色：绿。就是"文件名"和底部按钮的那个绿。
  /// 现在是 iOS 深色模式的系统绿。想换成自己的色值：
  ///     Color(red: 0.19, green: 0.82, blue: 0.35)      // 0~1 的 RGB
  ///     Color(hex: "#30D158")                            // 或者自己加个扩展
  static let accent = Color(hex: "#FFEAA7")

  /// 底部那排按钮（文字和图标）的颜色（p1列表.swift 里的 .tint 生效）。
  /// 例外：系统搜索项 🔍 是单色，不吃 tint；＋ 在 p1_底部按钮.swift 里
  /// 显式写了白色，覆盖掉了 tint。
  static let 底部胶囊 = Color.white
  /// 正文文字：白
  static let primaryText = Color.white

  /// 次要文字（摘要里的时间）：半透明白
  static let secondaryText = Color.white.opacity(0.70)

  /// 列表行的底色：很淡的一层白，做成"胶囊"的样子
  static let rowBackground = Color.white.opacity(0.07)

  /// 底部浮动条的底色
  static let barBackground = Color(white: 0.11)
}

// SwiftUI 的 Color 没有 hex 初始化，红色波浪线就是因为这个。
// 这里自己补一个：Color(hex: "#4ECDC4") 或 Color(hex: "4ECDC4") 都行。
extension Color {
  init(hex: String) {
    // 去掉 "#"，剩下的必须是 6 位十六进制
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard hex.count == 6, let rgb = UInt32(hex, radix: 16) else {
      self = .clear  // 写错了就变透明，方便一眼看出来
      return
    }
    self.init(
      red: Double((rgb >> 16) & 0xFF) / 255,  // 前两位
      green: Double((rgb >> 8) & 0xFF) / 255,  // 中间两位
      blue: Double(rgb & 0xFF) / 255  // 后两位
    )
  }
}
