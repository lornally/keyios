// ============================================================================
// 【全局配色】
// ============================================================================
// 改颜色只改这一个文件，整个 app 跟着变。
// ============================================================================

import SwiftUI

enum Theme {

    /// 背景：纯黑
    static let background = Color.black

    /// 主色：绿。就是"文件名"和底部按钮的那个绿。
    /// 现在是 iOS 深色模式的系统绿。想换成自己的色值：
    ///     Color(red: 0.19, green: 0.82, blue: 0.35)      // 0~1 的 RGB
    ///     Color(hex: "#30D158")                            // 或者自己加个扩展
    static let accent = Color(red: 0.19, green: 0.82, blue: 0.35)

    /// 正文文字：白
    static let primaryText = Color.white

    /// 次要文字（摘要里的时间）：半透明白
    static let secondaryText = Color.white.opacity(0.55)

    /// 列表行的底色：很淡的一层白，做成"胶囊"的样子
    static let rowBackground = Color.white.opacity(0.07)

    /// 底部浮动条的底色
    static let barBackground = Color(white: 0.11)
}
