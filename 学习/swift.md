# Swift 语法样例（只收本项目用到的）

每个样例：一段代码 + 一张表。片段按行拆开，不用先懂全文。

---

## 1. 变量声明

```swift
let entry: DiaryEntry
private let categories = ["待办", "持续", "暂缓", "完成", "全部"]
private static let weekdayNames = ["日", "一", "二", "三", "四", "五", "六"]
@State private var searchText = ""
```

| 片段 | 意思 |
| --- | --- |
| `let entry: DiaryEntry` | 不可变属性，名字 `entry`，类型 `DiaryEntry` |
| `private let categories = [...]` | `private` = 只有本文件能碰；类型推断出来，不用写 |
| `private static let weekdayNames = [...]` | `static` = 属于类型本身，不属于实例 |
| `@State private var searchText = ""` | `@State` = 值变了界面自动重画；`var` 可变 |
| `let` / `var` | 对应 JS 的 `const` / `let`。项目里默认全用 `let` |

---

## 2. 结构体声明

```swift
struct Summary: Identifiable, Hashable {
    let id = UUID()
    let time: String
    let text: String
}
```

| 片段 | 意思 |
| --- | --- |
| `struct Summary` | 声明一个结构体，名字 `Summary`（关键字在名字前） |
| `: Identifiable, Hashable` | 符合这两个协议。不是父类，是"能力清单" |
| `Identifiable` | 我能提供一个 `id`。列表（ForEach）靠它区分第几行 |
| `Hashable` | 我能比较相等，能当字典的 key |
| `let id = UUID()` | 不可变属性，初始值 `UUID()`（每次生成新值） |
| `let time: String` | 不可变属性，没有初始值 -> 构造时必须传 |
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
private static func parseDate(_ s: String, calendar: Calendar) -> Date?

guard let date = parseDate(stripped, calendar: calendar) else {
    return stripped
}

let days = calendar.dateComponents([.day], from: a, to: b).day ?? 0

let d = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
```

| 片段 | 意思 |
| --- | --- |
| `-> Date?` | 返回类型：可能是 Date，也可能是 nil。 |
| `guard let date = parseDate(...) else { return stripped }` | 不是 nil -> 赋值给 `date` 继续；是 nil -> 执行 else 里的 return |
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
let summaries: [Summary]
private let rawData: [(Int, [(String, String)])] = [
    (  0, [("10:12", "买菜"), ("11:22", "洗衣服")]),
    (  3, [("22:10", "加班到十点")]),
]
```

| 片段 | 意思 |
| --- | --- |
| `[Summary]` | 数组，元素类型 Summary |
| `[(Int, [(String, String)])]` | 从外往里读：数组；元素是元组；元组第一个是 `Int`，第二个是数组；那个数组的元素是 `(String, String)` 元组 |
| `(  0, [ ... ])` | 一项：第一个值 `0`（距今几天），第二个值是一个数组 |
| `("10:12", "买菜")` | 一个元组：按位置取，`.0`、`.1` |
| 元组 | 几个值临时捆一起，不用先声明类型，按位置取值 |

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
rawData.map { daysAgo, items in
    DiaryEntry(fileName: day(daysAgo), summaries: items.map { Summary(time: $0.0, text: $0.1) })
}
```

| 片段 | 意思 |
| --- | --- |
| `map { ... }` | map 对数组每个元素调一次大括号里的闭包，要求闭包返回新值 |
| `{ daysAgo, items in ... }` | `in` 前面是参数名，后面是闭包体。对应 JS 的 `(daysAgo, items) => { ... }` |
| `daysAgo, items` | rawData 的元素是个元组 `(Int, [...])`，元组可以直接拆成两个参数：`daysAgo` = `.0`，`items` = `.1` |
| 内层 `{ Summary(time: $0.0, text: $0.1) }` | 没写参数名时用 `$0` 指第一个参数。`items` 的元素是 `(String, String)`，所以 `$0.0` 是时间、`$0.1` 是内容 |
| `$1` | 需要第二个参数时是 `$1`，以此类推 |

### 9.3 `filter` 和 `contains` 的闭包

```swift
[1, 2, 3, 4].filter { $0 % 2 == 0 }            // 结果是 [2, 4]
diaries.filter { $0.text.contains(text) }
entry.summaries.contains { $0.text.contains(text) }
```

| 片段 | 意思 |
| --- | --- |
| `filter { ... }` | 对每个元素调一次闭包，返回 true 就留下 |
| `{ $0 % 2 == 0 }` | `$0` = 当前元素（一个数），返回"是不是偶数" |
| `{ $0.text.contains(text) }` | `$0` = 当前元素（DiaryEntry 或 Summary），`.text` 是它的属性 |
| 同一行里两个 `contains` | 外层是数组的 `contains`（吃闭包），`$0.text` 是字符串，内层是字符串的 `contains`（吃字符串） |

---

## 10. `guard` 和 `switch`

```swift
guard isSearching, !searchText.isEmpty else { return diaries }

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
let id = UUID()                  // 省: 右边能推出类型
let time: String = "10:12"      // 写了也合法，就是多余
let diaries: [DiaryEntry]        // 必须写: 值是从外面传的，没有初始值可推
```

| 片段 | 意思 |
| --- | --- |
| `id = UUID()` | 不写 `: UUID`，编译器从右边推出来 |
| `diaries: [DiaryEntry]` | 只有类型、没有值，只能手写类型 |
| 一般规则 | 右边能看出类型就省，看不出（或想强制）才写 |

---

## 12. 计算属性

```swift
private var filtered: [DiaryEntry] {
    guard isSearching, !searchText.isEmpty else { return diaries }
    return diaries.filter { ... }
}
```

| 片段 | 意思 |
| --- | --- |
| `var filtered: [DiaryEntry] { ... }` | 没有 `=` 和值，直接跟大括号 = 计算属性：每次读都现算，不存值 |
| `filtered` 的读法 | 不写括号，它不是函数 |

---

## 13. `@State` 和 `$`

```swift
@State private var searchText = ""
@State private var path: [DiaryEntry] = []

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
        WindowGroup { DiaryListView(diaries: sampleDiaries) }
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
| `var body: some Scene` | `some Scene` 读作"某种 Scene"。协议不能直接当返回类型写，加 `some` 就行 |
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
#Preview { DiaryListView(diaries: sampleDiaries) }
```

| 片段 | 意思 |
| --- | --- |
| `@` 开头 | 编译器标记，会生成你没写的代码 |
| `@Environment(\.dismiss)` | 取系统给的值（这里是"关掉自己"的函数） |
| `@ViewBuilder` | 允许大括号里写 if/else、ForEach。不加只能放单个值 |
| `#available(iOS 26.0, *)` | 版本判断。`*` = 其他平台不限制。老系统上大括号里那行编译时就不存在 |
| `#Preview { ... }` | 给预览工具单独画一屏用，app 运行时不执行它 |

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
| 为什么没有 `Theme: enum` | `enum` 是关键字不是类型，冒号后面只能放类型名。冒号那个位置是给协议留的（`: Identifiable`） |
| `DiaryNameAbbreviator` | 同一个用法：空 enum + 一堆 `static func` |
