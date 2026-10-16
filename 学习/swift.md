# Swift 语法样例（只收本项目用到的）

每个样例：一段代码 + 一张表。片段按行拆开，不用先懂全文。

---

## 1. 变量声明

```swift
let 文件名: String
private let categories = ["待办", "持续", "暂缓", "完成", "全部"]
private static let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
@State private var searchText = ""
```

| 片段 | 意思 |
| --- | --- |
| `let 文件名: String` | 不可变属性，名字 `文件名`，类型 `String`（没有初始值，类型必须写） |
| `private let categories = [...]` | `private` = 只有本文件能碰；类型推断出来，不用写 |
| `private static let weekdayNames = [...]` | `static` = 属于类型本身，不属于实例 |
| `@State private var searchText = ""` | `@State` = 值变了界面自动重画；`var` 可变 |
| `let` / `var` | 对应 JS 的 `const` / `let`。项目里默认全用 `let` |

---

## 2. 结构体声明

```swift
struct 日记: Identifiable, Hashable {
    let 文件名: String
    let 摘要: [String]
    var id: String { 文件名 }
}
```

| 片段 | 意思 |
| --- | --- |
| `struct 日记` | 声明一个结构体，名字 `日记`（关键字在名字前） |
| `: Identifiable, Hashable` | 符合这两个协议。不是父类，是"能力清单" |
| `Identifiable` | 我能提供一个 `id`。列表（ForEach）靠它区分第几行 |
| `Hashable` | 我能比较相等，能当字典的 key |
| `let 文件名: String` | 不可变属性，没有初始值 -> 构造时必须传 |
| `var id: String { 文件名 }` | 身份就是文件名（大括号里直接算，见 §12），不用 UUID |
| struct vs class | 区别在赋值行为：struct 整体复制（改 A 不影响 B），class 传同一个对象。两者都能有方法 |

---

## 3. 函数签名

```swift
static func abbreviate(_ fileName: String, today: Date = Date(),
                       calendar: Calendar = .current) -> String
```

| 片段 | 意思 |
| --- | --- |
| `static func abbreviate` | 属于类型的函数, 调用写 `DiaryNameAbbreviator.abbreviate(...)` |
| `_ fileName: String` | 一个 String 类型的参数 `fileName`. 开头的 `_` 表示**调用时不写标签** |
| `today: Date = Date()` | 一个 Date 类型的 `today`, **默认值是 `Date()`**(当场的时间) |
| `calendar: Calendar = .current` | 一个 Calendar 类型的 `calendar`, 默认值是 `Calendar.current`(系统当前日历) |
| `-> String` | 返回类型是 String |
| 不加 `_` 时 | 参数名自动兼任调用时的标签：`long(s: "abc")`，写 `long("abc")` 编译错误 |
| `.current` | 类型能从上下文看出时省略类型名，只写 `.成员` |

---

## 4. 参数带默认值的函数（空函数是干啥的）

> 回调钩子

```swift
var onSearch: () -> Void = {}
var onNew: () -> Void = {}
```

| 片段 | 意思 |
| --- | --- |
| `var onSearch` | 可变属性，名字 `onSearch` |
| `: () -> Void` | 类型是函数：`()` 没有参数，`-> Void` 没有返回值 |
| `= {}` | 初始值：一个什么都不做的空函数 |
| `BottomBar()` | 不传: 点按钮没反应 |
| `BottomBar(onSearch: { isSearching = true })` | 传了: 点了执行这个 |

---

## 5. `func` 和 `->` 的区别

```swift
func day(_ daysAgo: Int) -> String {
    return "..."
}
var onSearch: () -> Void = {}
```

| 片段 | 意思 |
| --- | --- |
| `func day(...)` | **声明**一个函数。`func` 是关键字，一个关键字对应一个种类（func/enum/struct/class） |
| `-> String` | **返回类型**String |
| `: () -> Void` | 整块是一个类型：函数类型。`()` 是参数列表，`-> Void` 是返回值 |
| 两种声明的关系 | 等价于 JS 的 `function day(...)` 和 `const cb = (...) => ...`：都是"一个函数"，只是写法不同 |

---

## 6. 可选类型 `?` 及三种拆法

```swift
static func 日期(_ fileName: String, calendar: Calendar = .current) -> Date?

guard let date = 日期(fileName, calendar: calendar) else {
    return 干净名(fileName)
}

let days = calendar.dateComponents([.day], from: a, to: b).day ?? 0

let d = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
```

| 片段 | 意思 |
| --- | --- |
| `-> Date?` | 返回类型：可能是 Date，也可能是 nil。 |
| `guard let date = 日期(...) else { return 干净名(fileName) }` | 不是 nil -> 赋值给 `date` 继续；是 nil -> 执行 else 里的 return |
| `.day` | `DateComponents` 的属性，类型是 `Int?` |
| `?? 0` | 不是 nil 就用左边，是 nil 就用右边的 0 |
| `...to: Date())!` | `!` = 我确定不是 nil，直接给值。猜错程序崩溃 |
| 总规则 | 变量默认不许是 nil，想允许必须在类型上加 `?` |

---

## 7. 字符串

```swift
return f.string(from: d) + " 日记"
if y == nowYear, m == nowMonth { 
  day =5
  return "本月\(day)日" 
}
return String(format: "%02d周%@", day, weekday(date, calendar))
```

| 片段 | 意思 |
| --- | --- |
| `+ " 日记"` | 拼字符串 |
| `"本月\(day)日"` | 拼day进去 = "本月5日" |
| `String(format: "%02d周%@", day, w)` | 老式格式化：`%02d` = 数字不足两位补零，`%@` = 塞一个对象 |

---

## 8. 数组和元组类型

```swift
let 摘要: [String]
let 日记表: [String: 日记]
private func 拆时间(_ 摘要: String) -> (时间: String?, 正文: String)
```

| 片段 | 意思 |
| --- | --- |
| `[String]` | 数组，元素类型 `String` |
| `[String: 日记]` | 字典：键是 `String`，值是 `日记`。从外往里读，方括号里的冒号左边是键的类型、右边是值的类型 |
| `(时间: String?, 正文: String)` | 元组：两个位置捆一起，还各起了名字。取的时候 `.时间` `.正文`，或者拆成两个变量 |
| 元组 | 几个值临时捆一起，不用先声明类型；它和数组一样能嵌套（元组里放数组、数组里放元组都行） |

---

## 9. 闭包

### 9.1 尾随闭包：大括号怎么就是参数

```swift
Button("关闭") { dismiss() }
Button("关闭", action: { dismiss() })   // 和上一行完全等价，写全是这样
```

| 片段 | 意思 |
| --- | --- |
| `{ dismiss() }` | 闭包：一小段代码，当成值传给 Button |
| `Button("关闭", action: { ... })` | Button 的最后一个参数。写全的样子 |
| `{ dismiss() }` 为什么能放括号外 | 最后一个参数是函数类型时可以写在括号外（尾随闭包） |
| 点击后 | 按钮执行这个闭包，`dismiss()` 被调用 |

### 9.2 `in` 和 `$0`

```swift
let 名字列表 = 日记表.values.map { $0.文件名 }
let 排序后  = 名字列表.sorted { a, b in a > b }
```

| 片段 | 意思 |
| --- | --- |
| `map { ... }` | map 对每个元素调一次大括号里的闭包，要求闭包返回新值（这里是"取出它的文件名"） |
| `{ $0.文件名 }` | 没写参数名时用 `$0` 指第一个参数。`日记表.values` 的元素是 `日记`，`$0` 就是其中一篇 |
| `{ a, b in a > b }` | `in` 前面是参数名，后面是闭包体。对应 JS 的 `(a, b) => { ... }`。比较要两个参数，所以是 `a`、`b` |
| `$1` | 不写参数名时，第二个参数是 `$1`，以此类推 |

### 9.3 `filter` 和 `contains` 的闭包

```swift
[1, 2, 3, 4].filter { $0 % 2 == 0 }                    // 结果是 [2, 4]
按日期排.filter { $0.文件名.contains(searchText) }      // 当前元素是 日记
日记.摘要.contains { $0.contains(searchText) }           // 当前元素是 String
```

| 片段 | 意思 |
| --- | --- |
| `filter { ... }` | 对每个元素调一次闭包，返回 true 就留下 |
| `{ $0 % 2 == 0 }` | `$0` = 当前元素（一个数），返回"是不是偶数" |
| `{ $0.文件名.contains(searchText) }` | `$0` = 当前那一篇日记，`.文件名` 是它的属性 |
| 同一行里两个 `contains` | 外层是数组的 `contains`（吃闭包），`$0` 是字符串，内层是字符串的 `contains`（吃字符串） |

---

## 10. `guard` 和 `switch`

```swift
guard isSearching, !searchText.isEmpty else { return 按日期排 }

switch days {
case ..<0:   return full(date)
case 0:      return "今天"
case 3...6:  return String(format: "%02d周%@", day, weekday(date, calendar))
default:     break
}
```

| 片段 | 意思 |
| --- | --- |
| `guard 条件 else { 离开 }` | 条件成立 -> 继续往下；不成立 -> 执行 else，else 必须离开当前作用域 |
| 条件中间的逗号 | "而且"，两个都要成立 |
| `!searchText.isEmpty` | `!` 取反：不是空字符串 |
| `case ..<0:` | 区间当条件：小于 0 |
| `case 3...6:` | 区间：3 到 6（含两头） |
| `default:` | 剩下的全部 |
| `break` | 占位：Swift 每个 case 自动结束，不用写 break 防穿透 |

---

## 11. 类型标注什么时候能省

```swift
let 文件名 = "26-10-16_日记"        // 省: 右边能推出类型
let 摘要: [String] = ["买菜"]       // 写了也合法，就是多余
let 日记表: [String: 日记]          // 必须写: 值是从外面传的，没有初始值可推
```

| 片段 | 意思 |
| --- | --- |
| `文件名 = "26-10-16_日记"` | 不写 `: String`，编译器从右边推出来 |
| `日记表: [String: 日记]` | 只有类型、没有值，只能手写类型 |
| 一般规则 | 右边能看出类型就省，看不出（或想强制）才写 |

---

## 12. 计算属性

```swift
private var 过滤后: [日记] {
    guard isSearching, !searchText.isEmpty else { return 按日期排 }
    return 按日期排.filter { ... }
}
```

| 片段 | 意思 |
| --- | --- |
| `var 过滤后: [日记] { ... }` | 没有 `=` 和值，直接跟大括号 = 计算属性：每次读都现算，不存值 |
| `过滤后` 的读法 | 不写括号，它不是函数 |

---

## 13. `@State` 和 `$`

```swift
@State private var searchText = ""
@State private var path: [日记] = []

NavigationStack(path: $path) { ... }
.searchable(text: $searchText, isPresented: $isSearching, prompt: "搜索日记")
```

| 片段 | 意思 |
| --- | --- |
| `@State` | 值变了，用到它的界面自动重画 |
| `searchText` | 当时的值 |
| `$searchText` | 变量本身（绑定），传给别人替你写的时候用 |
| `path: $path` | NavigationStack 替你写这个数组（点返回时删最后一条） |

---

## 14. `body` / `some`

```swift
@main
struct KeyiosApp: App {
    var body: some Scene {
        WindowGroup { DiaryListView(日记表: 日记表) }
    }
}

struct DiaryListView: View {
    var body: some View { ... }
}
private struct BarButton<Label: View>: ToolbarContent { ... }
```

| 片段 | 意思 |
| --- | --- |
| `@main` | 程序入口标记。整个 app 只有一个 |
| `struct KeyiosApp: App` | 符合 App 协议 = 能被系统当"一个 app"启动 |
| `var body: some Scene` | `Scene` 是**协议**不是能造值的类型。`some Scene` = 一个 **opaque** 类型（见 §21），底层是**某个具体类型**，名字不写。写成 `Scene` 或 `any Scene` 都编译不过 |
| `WindowGroup { ... }` | 构造调用 + 尾随闭包 |
| `body` 的固定写法 | App -> `some Scene`；View -> `some View`；ToolbarContent -> `some ToolbarContent` |
| `BarButton<Label: View>` | 泛型：`Label` 是占位名字，约束"某种 View"，实际是啥由调用处决定 |

---

## 15. `@` 和 `#` 开头的标记

```swift
@main
@State private var searchText = ""
@Environment(\.dismiss) private var dismiss
@ViewBuilder var label: () -> Label
if #available(iOS 26.0, *) { ... }
#Preview { DiaryListView(日记表: 日记表) }
```

| 片段 | 意思 |
| --- | --- |
| `@` 开头 | 编译器标记，会生成你没写的代码 |
| `@Environment(\.dismiss)` | 取系统给的值（这里是"关掉自己"的函数） |
| `@ViewBuilder` | 允许大括号里写 if/else、ForEach。不加只能放单个值 |
| `#available(iOS 26.0, *)` | 版本判断。`*` = 其他平台不限制。**是运行期判断，不是编译开关** —— 见下 |
| `#Preview { ... }` | 给预览工具单独画一屏用。app 里没有一行代码调它，但**它照样被编进 app** —— 见下 |

### 15.1 `#available`：块里的代码照样要编译

```swift
if #available(iOS 26.0, *) {
    Text("新").没有这个函数()     // ❌ 照样报错: value of type 'Text' has no member '没有这个函数'
} else {
    Text("旧")
}
```

如果真是"老系统上编译时就不存在"，编译器就不该管这块里的内容 —— 但它一字一句地管。真实编出来的是一次**对系统版本的询问**（`-emit-sil` 里能看到这个符号）：

```swift
_stdlib_isOSVersionAtLeast(iOS, 26, 0)   // 运行到这一行才问系统版本, 拿 true/false 决定走哪支
```

所以 `#available` 里能写 iOS 26 才有的 API、老系统上又不崩，靠的是"**代码编进去了，但跑到这里时判断为 false，不执行**"。

### 15.2 `#Preview`：不执行，但会被编进去

`#Preview { Text("hi") }` 展开出来是个挂在系统登记表上的结构体（实测 `-dump-macro-expansions`）：

```swift
struct $...PreviewRegistry: DeveloperToolsSupport.PreviewRegistry {
    static func makePreview() -> Preview { Preview { Text("hi") } }
}
```

它外面**没有** `#if DEBUG`（实测：不开 DEBUG 编译，`.o` 里照样有这个符号）。区别只在"谁去调它"：app 自己的代码一处都不调，只有预览工具来查这张表。

后果，用本项目的话说：`p1列表单行.swift` 末尾那个 `#Preview` 里写了 `DiaryRowView(日记: ...)`。哪天你把 `DiaryRowView` 的参数改个名，忘了改 `#Preview` 里这行 —— **整个 app 编不过**，哪怕 app 跑起来根本不执行预览。

---

## 16. 声明关键字和类型分两个语法位置的说明

```swift
enum Theme { static let background = Color.black }
let color: Calendar
```

| 片段 | 意思 |
| --- | --- |
| `enum Theme { }` | 关键字在前：声明"Theme 是个枚举"。空 enum 当命名空间用，只挂 static 成员，不能被 `Theme()` 实例化 |
| `let color: Calendar` | 冒号后：说"color 的类型是 Calendar" |
| 为什么没有 `Theme: enum` | 冒号那个位置要的是**类型**，而 `enum` 是关键字不是名字（编译器原话：`expected type`）。对 struct/enum 来说那个位置必须放**协议**（编译器原话：`inheritance from non-protocol type 'Int'`）；class 还能放父类 |
| `DiaryNameAbbreviator` | 同一个用法：空 enum + 一堆 `static func` |

---

## 17. 数据结构有哪几种，区别在哪

| 类型 | 长什么样 | 有序? | 靠什么取元素 | 变长? | 值/引用 | 项目里的 |
| --- | --- | --- | --- | --- | --- | --- |
| 数组 `[T]` | `["买菜", "洗衣服"]` | 有序（按位置） | 下标 `[0]` | 变长 | 值 | `摘要: [String]`、`categories` |
| 字典 `[K: V]` | `["26-10-16_日记": 日记(...)]` | **无序** | 键 | 变长 | 值 | `日记表` |
| 集合 `Set<T>` | `Set(["a", "b"])` | 无序 | 只能问"在不在" | 变长 | 值 | （还没用到）自动去重 |
| 元组 `(A, B)` | `(时间: "10:12", 正文: "买菜")` | 有序（按位置） | `.0` / `.时间` | 定长 | 值 | `拆时间()` 的返回类型 |
| 结构体 `struct` | `struct 日记 { let 文件名: String }` | 字段固定 | 字段名 | — | 值 | `日记` |
| 类 `class` | `class 下载进度 { var 已完成 = 0 }` | 字段固定 | 字段名 | — | **引用** | （还没用到） |
| 枚举 `enum` | `enum 状态 { case 待办, 持续 }` | — | case 名 | 固定几个 | 值 | `Theme`、`DiaryNameAbbreviator` |

两条最重要的分界线：

1. **值 vs 引用** —— 数组/字典/集合/元组/struct/enum **都是值类型**：赋值和传参时整个复制，改一份不影响另一份。只有 `class` 是引用类型：传的是同一个对象，这边改了那边看得见。项目里目前一个 class 都没有，这是有意的 —— 默认就该用 struct。
2. **现成容器 vs 自造类型** —— 前四种（数组/字典/集合/元组）是"装现成东西的容器"，装谁都行；后三种（struct/class/enum）是"自己造的类型"，一个字段一个字段定义出来，还能挂方法、协议。

三个容易漏的：

- **可选 `T?` 本身是个枚举**（`Optional` 只有两种 case：有值 / nil）。所以 `??`、`if let`、`guard let` 拆的其实是枚举（见 §6）
- **函数/闭包 `(A) -> B` 也是能存进变量的值**：`var onSearch: () -> Void = {}` 就是"一个装着函数的变量"（见 §4）
- **String 是个 struct**（所以字符串也是值语义，改一个副本不影响原串）

### 各自的例子（造一个 → 用一下 → 看结果）

```swift
// ── 数组: 有序, 下标取, 允许重复 ──
let 概览 = ["10:12 买菜", "11:22 洗衣服"]
概览[0]                                  // "10:12 买菜"
概览.count                               // 2
概览 + ["21:00 散步"]                     // 拼出一串新的, 3 条

// ── 字典: 键取, 键唯一, 无序 ──
let 表 = ["26-10-16_日记": 日记(文件名: "26-10-16_日记", 摘要: ["10:12 买菜"])]
表["26-10-16_日记"]?.摘要                  // ["10:12 买菜"]   (? 是因为可能取不到)
表["没有这个"]                            // nil

// ── 集合: 只关心"在不在", 自动去重 ──
let 已读 = Set(["T1", "T2", "T1"])
已读.count                               // 2  —— 重复的自动没了
已读.contains("T1")                      // true

// ── 元组: 几个值临时捆一起 ──
let 拆 = 拆时间("10:12 买菜")
拆.时间                                   // "10:12"  (类型 String? —— 可能没有)
拆.正文                                   // "买菜"
let (时间, 正文) = 拆时间("10:12 买菜")    // 也可以一步拆成两个变量 → 这叫**解构**

// ── struct: 造一个, 取字段, 值语义(复制) ──
let 今天 = 日记(文件名: "26-10-16_日记", 摘要: ["10:12 买菜"])
今天.摘要.count                           // 1
let 副本 = 今天                           // 整个复制一份, 后来的改动与 今天 无关

// ── class: 引用语义(同一份, 共享) ──
class 下载进度 { var 已完成 = 0 }
let 甲 = 下载进度()
let 乙 = 甲                               // 不是复制, 是同一个对象
乙.已完成 = 3
甲.已完成                                 // 3  —— 改乙就是改甲

// ── enum: 值只有固定几种; switch 必须一个不漏 ──
enum 待办状态 { case 待办, 持续, 暂缓, 完成 }
let 状态 = 待办状态.待办
状态 == .待办                             // true —— 简单 enum 自动能比相等, 不用声明 Equatable

switch 状态 {
case .待办: print("还没开始")              // 四个 case 少写一个, 编译直接报错
case .持续: print("在做")
case .暂缓: print("放一放")
case .完成: print("完事了")
}

// 想让"所有 case"变成一个数组 (底部按钮那排将来就能这么写):
enum 待办状态: CaseIterable { case 待办, 持续, 暂缓, 完成 }
待办状态.allCases                         // [待办, 持续, 暂缓, 完成]
```

**解构**：只有**元组**能 `let (a, b) = ...` 这样一步拆开。enum 的关联值只能在 `switch` / `if case` 里拆；struct / class 是取字段（`今天.摘要`），数组是取下标（`概览[0]`），都不叫解构。

| 问自己 | 就用 |
| --- | --- |
| 就是一串，按顺序 | 数组 |
| 拿一个键/名字查东西 | 字典 |
| 只判断"有没有"，要自动去重 | 集合 |
| 临时捆几个值，用完就散 | 元组 |
| 一组字段捆成新类型 | struct（默认） |
| 需要共享同一份、要继承 | class |
| 值只有固定这几种 | enum |

---

## 18. 函数

```swift
let f: (Int) -> Int = { $0 + 1 }    
func g(x: Int) -> Int { x + 1 }  
```

| 写法                | 标签（**调用时**写） | 内部名（**函数体里**用） | 怎么调用   |
| ------------------- | -------------------- | ------------------------ | ---------- |
| `func g(x: Int)`    | `x`                  | `x`                      | `g(x: 5)`  |
| `func g(数 x: Int)` | `数`                 | `x`                      | `g(数: 5)` |
| `func g(_ x: Int)`  | 无                   | `x`                      | `g(5)`     |



## 19. Swift 的类型清单（就这些）

| 分类            | 写法            | 例子                                                         |
| --------------- | --------------- | ------------------------------------------------------------ |
| **struct**      | `struct X {}`   | `Int`、`Bool`、`String`、数组、字典 —— **标准库里全是 struct**（`public struct Int`、public struct Array） |
| **enum**        | `enum X {}`     | `Optional`（就是 `T?`，原文 `public enum Optional<Wrapped>`） |
| **class**       | `class X {}`    | 项目里没有                                                   |
| **actor**       | `actor X {}`    | 项目里没有（和 class 一样是引用类型，多了并发隔离）          |
| **元组 / 函数** | 无关键字，内建  | `(Int, String)`、`(Int) -> Int`                              |
| **protocol**    | `protocol X {}` | `View`、`Scene`、`Identifiable`                              |
| **existential** | 无关键字，内建  | `any 会游泳`、`Any`（= 不要求任何东西的 any）                |
| **opaque**      | `some 协议`     | `some View`、`some Scene`                                    |

造类型的关键字 5 个（struct / enum / class / actor / protocol）。别的语言里那些全是你熟悉的这几个变出来的：

```swift
int / string / 数组 / 字典  →  struct（标准库写的）
null                        →  enum（Optional）
元组 / 函数                  →  内建的复合类型
抽象类 / 接口                →  protocol
```

能造值的类型（狭义）= struct / enum / class / actor / 元组 / 函数。协议不在里面。

## 20. 泛型

泛型是"类型带参数"的机制，struct / enum / class / 函数都能带（刚跑通）：

```swift
struct 箱子<T> { var 内容: T }          // 泛型 struct —— Array / Dictionary / Set 就是
enum 结果<T>   { case 成功(T) }         // 泛型 enum   —— Optional 就是
class 栈<T>    { var 项: [T] = [] }     // 泛型 class
func 取第一个<T>(_ a: [T]) -> T? { }    // 泛型函数
```



## 21. 抽象类/接口 ↔ 协议：**对**

当值的类型时, 协议名有两种写法（下面每行注释都是实测输出, 见 research/some与any.swift 实验 1、2）:

```swift
protocol 会游泳 {}                         // 没有 associatedtype
protocol 容器 { associatedtype 元素 }       // 有 associatedtype
struct 青蛙: 会游泳 {}
struct 箱子: 容器 { typealias 元素 = Int }

let a: 会游泳 = 青蛙()       // ✓ 零警告
let b: any 会游泳 = 青蛙()   // ✓ 零警告 —— 没有 associatedtype: 裸名、any 都行

let c: 容器 = 箱子()         // ⚠️ 旧写法, 警告:
                            //    use of protocol '容器' as a type must be written
                            //    'any 容器'; this will be an error in a future Swift language mode
let d: any 容器 = 箱子()     // ✓ 零警告 —— 有 associatedtype 的写成 any
```

`associatedtype` = 协议里的**占位类型名**, 谁符合谁填:

```swift
protocol 容器 { associatedtype 元素 }
struct 箱子: 容器 { typealias 元素 = Int }   // 填法一: 明写

protocol 有内容 { associatedtype 元素; var 内容: [元素] { get } }
struct 筐: 有内容 { var 内容: [Int] }        // 填法二: 从用它的地方推出来 → 元素 = Int

struct 日记: Identifiable { var id: String { 文件名 } }   // Identifiable 的 ID = String（填法二）
```

| 位置           | 写法                                                         | 意思                   |
| -------------- | ------------------------------------------------------------ | ---------------------- |
| ① **冒号后面** | `struct 青蛙: 会游泳`、`enum 蝌蚪: 会游泳`、`class 鱼: 会游泳` | 符合                   |
| ② **泛型约束** | `func f<T: 会游泳>(_ x: T)`、`struct 箱子<T: 会游泳>`        | 约束                   |
| ③ **值的类型** | `var a: any 会游泳` / `var b: some 会游泳`                   | any和some都写得出来，但**只有 `any` 能换值**（见下） |

`any` 把 protocol 变成一个 **existential** 类型（所有符合者共用一个）；`some 协议` 是 **opaque** 类型.

| 写法        | 落在哪一档                                   | 是新造的吗                                                   |
| ----------- | -------------------------------------------- | ------------------------------------------------------------ |
| `some 协议` | §19 里的 opaque                              | **是** —— 底层类型由函数体定（4 种之一）（struct / enum / class / actor） |
| `any 协议`  | §19 里的 existential（官方名，没有中文对译） | **是** —— 从协议造出来的一个新类型                           |

`any 会游泳` 是一个类型，青蛙鱼都装得进；`some 会游泳` 每个函数各一个：

```swift
protocol 会游泳 {}
struct 青蛙: 会游泳 {}
struct 鱼:   会游泳 {}

var 任意: any 会游泳 = 青蛙()
任意 = 鱼()                                  // ✓ any: 一个类型, 谁都能装

func 造甲()  -> some 会游泳 { 青蛙() }
func 造甲2() -> some 会游泳 { 青蛙() }        // 协议一样, 函数体一字不差

//为了测"是不是同一个类型"临时造的函数
func 同一个类型<T>(_ a: T, _ b: T) {}   // 探针: 两个参数共用一个 T, 只有"同一个类型"才编得过

同一个类型(造甲(), 造甲2())
// ❌ error: conflicting arguments to generic parameter 'T'
//    ('some 会游泳' (result type of '造甲') vs. 'some 会游泳' (result type of '造甲2'))

同一个类型(造甲(), 造甲())   // ✓ 同一个函数调两次: 还是同一个类型（按"声明"算, 不是按"每次调用"）

//`type(of:)` 是标准库的。
type(of: 造甲()) == 青蛙.self               // true —— 运行时那个值就是 青蛙
```

### `some` 当变量类型 = 上了锁：写得出来，但一个值都换不了

```swift
var 甲: any 会游泳 = 青蛙()
甲 = 鱼()                     // ✓ any: 想装谁装谁

var 乙: some 会游泳 = 青蛙()
乙 = 青蛙()                   // ❌ error: cannot assign value of type '青蛙' to type 'some 会游泳'
乙 = 鱼()                     // ❌ 一样报错
```

`some` 读作"**某个我不说的类型**"。这个类型在**写下这行的时候**就定死了，之后谁都不许往里塞 —— 连同一个 `青蛙` 都不行，因为"写出来的 `青蛙`"和那个藏起来的类型，编译器当成两回事。（Swift 5 模式、6 模式实测都一样。）

所以位置是这样分的：

| 位置                   | 写什么                            | 例子                                                |
| ---------------------- | --------------------------------- | --------------------------------------------------- |
| 返回类型               | `some`（就它的主场）              | `var body: some View`、`func 造() -> some 会游泳`   |
| 函数参数               | `some` = 泛型参数的简写，可以     | `func 收(_ x: some 会游泳)`                         |
| **变量的类型**         | `any`（或直接写具体类型 `青蛙`）  | `var 甲: any 会游泳 = 青蛙()`                       |

**`func 同一个类型<T>(_ a: T, _ b: T) {}`**

| 片段         | 意思                                                         |
| ------------ | ------------------------------------------------------------ |
| `func`       | 声明函数                                                     |
| `同一个类型` | 函数名。我瞎起的，叫 `是不是一回事`、`day`、`abbreviate` 都一样，就是个名字 |
| `<T>`        | 泛型参数（§20 那种）：`T` 是**占位类型名**，调用时由编译器填成实际类型 |
| `_ a: T`     | 第一个参数叫 `a`，类型写的是 `T`；`_` = 调用时不写标签       |
| `_ b: T`     | 第二个参数 `b`，**也写 `T`** —— 两个参数共用同一个 T         |
| `{}`         | 函数体空的：它什么都不干，作用全在签名上                     |

关键就是"两个参数共用同一个 `T`"：编译器没法把 `T` 同时填成两种类型。所以 `同一个类型(x, y)` 能编过的唯一条件就是 x、y 是同一个类型 —— 等于把它变成了一个编译错误开关。实测：

```swift
同一个类型(青蛙(), 青蛙())   // ✓ 编过
同一个类型(青蛙(), 鱼())     // ❌ error: conflicting arguments to generic parameter 'T' ('青蛙' vs. '鱼')
```

**`type(of: 造甲()) == 青蛙.self`**

| 片段               | 意思                                                         |
| ------------------ | ------------------------------------------------------------ |
| `type(of:)`        | 标准库的函数：传一个值进去，返回它在**运行时**实际是什么类型。`of` 是参数标签 |
| `type(of: 造甲())` | 结果就是 `青蛙`                                              |
| `.self`            | 接在类型名后面 = 把"类型"本身当值用。`青蛙.self` 是"青蛙这个类型"，不是一只青蛙 |
| `==`               | 比较相等                                                     |
| 整句               | 问"造甲() 运行时那个值是不是青蛙类型" → `true`               |

**为什么两个都要**：一个问编译期，一个问运行期 —— 而这两个答案不一样，正是这段要说的：

- `同一个类型(...)` 报错 = **编译期**：编译器把两个函数的 `some 会游泳` 当成两个不同类型
- `type(of: ...)` 是 true = **运行期**：那个值就是一只青蛙

进一步实测：

```swift
同一个类型(造甲(), 造甲())    // ✓ 编过
let 一堆 = [造甲(), 造甲()]   // ✓ 连数组都放得进, 2 个元素
```

所以那句"每个 some xxx 都是不同的类型"要改成：**每个「声明」一个类型，不是每次调用一个**。`造甲` 调一万次，拿到的都是同一个类型；只有换一个函数（`造甲2`）才变成另一个类型。

再往下推一层（顺手也测了，`造` 是带泛型的）：

```swift
func 造<T>(_ x: T) -> some 会游泳 { 青蛙() }

同一个类型(造(1), 造(1))      // ✓ 同一个函数 + 同一个泛型实参 = 同一个类型
同一个类型(造(1), 造("a"))    // ❌ error: conflicting arguments to generic parameter 'T' ('Int' vs. 'String')
```

所以完整的规则是：**声明 + 泛型实参** 才算一个 —— `造<Int>()` 和 `造<String>()` 是两个类型。

---

## 22. 怎么在命令行跑 Swift

和 Python 几乎一一对应（都在终端实测过）：

| 想干啥 | Swift | Python 对应 |
| --- | --- | --- |
| 跑一个文件 | `swift 文件.swift` | `python x.py` |
| 交互式 | `swift repl` | `python` |
| 一行式 | `swift -e 'print(6*7)'` | `python -c 'print(6*7)'` |
| 编成可执行文件再跑 | `swiftc 文件.swift -o 名字 && ./名字` | （没有这么直接的对等物） |

```bash
$ swift /tmp/a.swift            # 直接跑
$ echo 'print(6*7)' | swift repl   # 交互式的管子版, 输出 42
$ swift -e 'print(6*7)'         # 42
```

两条边界，分清"跑起来看界面"和"只检查能不能编"：

- 纯逻辑（字符串、数组、日期、算法）随便在终端跑
- 用到 SwiftUI / UIKit 的代码**不能在终端跑起来看界面** —— 那要模拟器，只能走项目里的 `./build.sh`。
  但**"只检查能不能编"（不跑）在终端就能做**，加两个参数：

  ```bash
  xcrun -sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator Keyios/*.swift
  ```

  实测：整份项目源码这样检查是**通过**的（research/ 里那几段实验用的就是这条命令）。
  不加 `-sdk iphonesimulator` 会按 macOS 编，同一份代码立刻报 8 个错 —— 全是 `'bottomBar' is unavailable in macOS`，
  也就是说挡路的是**iOS 专属的 API**，不是 SwiftUI 本身。

- 以后 dog 解析这类纯逻辑抽成 SwiftPM 包，就能 `swift test` 在终端里毫秒级验证（不用开模拟器）
