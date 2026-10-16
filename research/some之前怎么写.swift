// ============================================================================
// 【实验: 没有 some 的年代, "返回某个 View" 怎么写】
// ============================================================================
// 编译:
//   xcrun -sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator \
//       research/some之前怎么写.swift
//
// 四种写法都编过一遍:
//   ①②③ ✅ 能编译   ④ ❌ 故意留的错(注释掉了), 看它怎么崩的
// ============================================================================

import SwiftUI

// ① 现在的写法: some (真名藏起来)
struct 甲: View {
    var body: some View {
        HStack(spacing: 10) { Text("买菜"); Text("洗衣服") }
    }
}

// ② 老办法一: 把真名一个字一个字写出来
struct 乙: View {
    var body: HStack<TupleView<(Text, Text)>> {
        HStack(spacing: 10) { Text("买菜"); Text("洗衣服") }
    }
}

// ③ 老办法二: 装进类型擦除盒子 (SwiftUI 的 AnyView)
struct 丙: View {
    var body: AnyView {
        AnyView(HStack(spacing: 10) { Text("买菜"); Text("洗衣服") })
    }
}

// ④ 老办法一的代价: 同样的签名, 内容加一个 Text 就崩
// struct 丁: View {
//     var body: HStack<TupleView<(Text, Text)>> {
//         HStack(spacing: 10) { Text("买菜"); Text("洗衣服"); Text("散步") }
//     }
// }
// error: conflicting arguments to generic parameter 'Content'
//        ('HStack<TupleView<(Text, Text)>>' vs. 'HStack<TupleView<(Text, Text, Text)>>')
