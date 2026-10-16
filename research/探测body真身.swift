// ============================================================================
// 【实验: body 的真身是什么类型 —— 为什么必须写 some】
// ============================================================================
// 要带上 app 的源码一起类型检查 (因为要用项目里的类型):
//   xcrun -sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator \
//       Keyios/*.swift research/探测body真身.swift
//
// 玩法: 故意把 body 赋给 Int, 让编译器把真实类型打在错误信息里。
//
// 实测结论 1: 编译器只会说 'some View' —— 就算探测代码和 body 在同一个文件里也一样。
//             (我原以为"同文件能看见真身", 实测推翻: 出了 body 自己那个声明, 谁看都是 some)
//
// 实测结论 2: 把 body 里的表达式抄出来单独问, 真相是这样 ——
//     Text("hi")                          → Text                              写得出
//     HStack { Text; Text }               → HStack<TupleView<(Text, Text)>>   写得出
//     Text("a").foregroundStyle(.white)   → Text                              (Text 自己的重载)
//     Text("a").fontWeight(.semibold)     → Text                              (同上)
//     Text("a").font(.system(size: 15))   → Text                              (同上)
//     Text("a").lineLimit(1)              → Text                              (同上)
//     Text("a").frame(maxWidth: ..., ...) → some View                         ✗ 断在这
//     Text("a").padding(.vertical, 13)    → some View                         ✗
//     Text("a").background(Capsule())     → some View                         ✗
//
// 实测结论 3: 翻 SDK 看 SwiftUI 自己的声明 —— 它自己就在用 some:
//     public func frame(...)   -> some View
//     public func padding(...) -> some View
//
// 所以 DiaryRowView.body 这种"一串修饰符"的类型, **根本写不出来** ——
// 不是太长, 是链条中段就断了。some 不是可有可无的语法糖, 是唯一能描述它的办法。
// ============================================================================

import SwiftUI

private let 探测1: Int = DiaryListView(日记表: [:]).body
private let 探测2: Int = DiaryRowView(日记: 日记表["摩托车"]!).body
