// ============================================================================
// 【实验: 协议当类型 / some / any】
// ============================================================================
// 单独就能编, 不依赖项目代码:
//   xcrun -sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator \
//       research/some与any.swift
//
// 约定: 每一段都是"跑过一遍确认过结果"的。故意写错的行都注释掉了,
//       错误原文写在旁边 —— 想复现就取消注释再编一次。
// ============================================================================

import SwiftUI

// ── 实验 1: 带关联类型的协议, 裸名当类型 → 警告 ──────────────────────────
protocol 容器 { associatedtype 元素 }
struct 箱子: 容器 { typealias 元素 = Int }

let a: 容器 = 箱子()          // ⚠️ warning: use of protocol '容器' as a type must be
                             //    written 'any 容器'; this will be an error in a future
                             //    Swift language mode [#ExistentialAny]
let b: any 容器 = 箱子()      // ✓ 明写盒子, 不警告
let c: [any 容器] = []        // ✓ 数组里装盒子也行

// ── 实验 2: 空协议不警告 (没有关联类型, 裸名和 any 是一回事) ─────────────
protocol 会游泳 {}
struct 青蛙: 会游泳 {}
let d: 会游泳 = 青蛙()        // ✓ 零警告

// ── 实验 3: 要求"类型本身符合协议"时, any 过不了 ────────────────────────
protocol 货架 {              // 和 App 同构: 要求关联类型本身符合 容器
    associatedtype 放的: 容器
    var 内容: 放的 { get }
}
struct 甲: 货架 { var 内容: 箱子 { 箱子() } }         // ✓ 具体类型
struct 丙: 货架 { var 内容: some 容器 { 箱子() } }    // ✓ some
// struct 乙: 货架 { var 内容: any 容器 { 箱子() } }  // ❌ error: type '乙' does not conform to protocol '货架'

// ── 实验 4: 协议的冒号位 (struct X: 协议) ───────────────────────────────
struct 好: 会游泳 {}          // ✓
// struct 坏: Int {}          // ❌ error: inheritance from non-protocol type 'Int'
// struct 更坏: enum {}       // ❌ error: expected type

// ── 实验 5: SwiftUI 的 body 为什么只能 some ─────────────────────────────
// struct 甲App: App { var body: Scene     { WindowGroup { Text("x") } } }  // ❌ does not conform to protocol 'App'
// struct 乙App: App { var body: any Scene { WindowGroup { Text("x") } } }  // ❌ 同上
struct 丙App: App {                                                          // ✓
    var body: some Scene { WindowGroup { Text("x") } }
}
