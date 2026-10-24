# 学习建议

### 关键区别：**"用" `some` 和"设计" `some` 是两码事**

你躲不掉的是**消费** `some`（在系统给的签名里照着写），但你可以先躲掉**生产** `some`（自己设计带不透明类型的 API）。

*   **消费层面（躲不掉，但很简单）**：`var body: some View { ... }` 就是模板。你不需要理解 `some` 的类型擦除原理，只需要知道"这里返回一个具体的 View，编译器帮我隐藏类型"。照着写就行，**不理解也能跑**。
*   **生产层面（可以推迟）**：比如你自己写一个函数 `func makeCard() -> some View`，或者设计一个带 `associatedtype` 的协议。这些才是真正抽象、容易踩坑的地方。**初学阶段完全可以不写**，用具体类型（如 `VStack<T>`、`Text`）或者 `AnyView`（虽然性能差点，但简单）替代。

### 那 `some` 到底要不要懂？——**用到哪懂到哪，别提前啃**

给你的实操路径：

1. **第一周**：把 `some View` 当关键字背下来。`body` 里就写 `some View`，闭着眼睛写。不用管它为什么不是 `View`。
2. **遇到第一个"报错说类型不匹配"**：比如你想在 `if/else` 两个分支返回不同 View，编译器说"无法推断"，这时候你才需要知道：`some View` 要求**单一具体类型**，`if/else` 两个分支类型不同就满足不了，得用 `@ViewBuilder` 或者包一层 `AnyView`。**这个坑撞一次就懂了，比看十篇博客管用**。
3. **`associatedtype` 同理**：SwiftUI 的 `View` 协议本身带 `associatedtype Body`，但系统帮你填了。你自己写协议时才会撞上"协议带 associatedtype 不能直接当类型用"的问题——那时候再学 `any` 和泛型约束，**有具体场景驱动，理解成本低得多**。

### 修正后的建议

*   **`some View` / `some Scene`：当语法模板用，别当类型理论学**。你 Python 写 `def __init__(self):` 时也没深究过描述符协议，一个道理。
*   **真正要提前建立习惯的仍然是并发隔离**：从第一个 `async` 网络请求开始就标 `@MainActor`，用 `struct` 做数据模型。这块是持续性摩擦，早养成习惯早省事。
*   **`some`/`any`/`associatedtype` 的"生产侧"**：等你 App 有了两三个页面、开始想"抽个通用组件"的时候再碰，那时候你有真实需求，学起来不抽象。

**入口处的 `some` 是"必答题但不是难题"**，照写就行；真正难的是想自己抽象。"绕开"不准确，应该是"**先消费、后生产**"。



# 符号要点



## 1. `var` 关键字

```swift
var a: Int = 42   // 存储属性，直接赋值
var a: Int { 42 } // 这是**计算属性（computed property）**的语法，花括号里是 getter 的返回值。`a` 每次访问时都会执行花括号里的代码。
// 两者不同：前者是存储值，后者是每次访问时计算。
```

## 2. `struct` / `enum` / `class`

```swift
struct Point {
    // 这里是类型成员（属性、方法等），不是"值"
    var x: Int   // 成员声明
    var y: Int
}
struct 日记: Identifiable, Hashable {
    let 文件名: String
    let 摘要: [String]
    var id: String { 文件名 } 
    // 这里就是get只读属性, 现在的写法是“零成本的别名”：值仍然只有一份，就在 文件名 里。
}
```

具体含义：

- **没有独立的 `id` 存储**。结构体里只有 `文件名` 和 `摘要` 两个字段，`id` 不占内存、不能被赋值（只读）。
- 每次读 `某篇.id`，就现场取一次 `文件名` 的值返回。因为 `文件名` 是 `let`，值不变，所以读到的 `id` 永远稳定。
- 这里是为了满足 `Identifiable` 协议的要求（`var id { get }`）：列表要用稳定的身份标识，而字典的 key 本来就是文件名，直接拿它当身份，就不用再造 UUID。
- 顺带一提：`id` 是计算属性，不参与编译器合成的 `Hashable`/`==`——相等性只看存储属性 `文件名` 和 `摘要`。

### Swift 用同一套 { } 大括号语法承载了多种语义：

| 花括号位置       | 里面是      | 语义            |
| ---------------- | ----------- | --------------- |
| var a: T { ... } | getter 代码 | 运行时求值 → 值 |
| struct S { ... } | 成员声明    | 定义类型结构    |
| func f() { ... } | 语句        | 调用时执行      |
| if x { ... }     | 语句        | 条件成立时执行  |
| 闭包 { ... }     | 语句        | 作为值传递      |

### 冒号的2大类用法:

```swift
// 类型标注
let name: String = "Swift" //类型
struct MyStruct: Equatable { } //协议
class MyClass: NSObject { } //继承
func f<T>(_ x: T) where T: Equatable {} //`where` 子句中 `T: P` 表示 T 受协议 P 约束
associatedtype E: Equatable //协议中约束关联类型遵循某协议


```

```swift
// 各种语法
let dict = ["key": "value"] //字典
let result = condition ? "yes" : "no" //三元
dict.updateValue("飞机", forKey: 21) //参数标签:值
case let x as String: //case
case 1: ... //case
outer: for _ in 0..<3 {} // 跳转标签，供 `break outer` 使用
```



# 语言组织和序

```sh
target/module（模块）
  └─ 文件夹（仅组织代码，不影响可见性）
      └─ 文件
          └─ 类型：class / struct / enum / actor / protocol / extension
              └─ 成员：方法、计算属性、嵌套类型, 函数一般组织在enum里面, enum作为函数的命名空间
                  └─ 嵌套类型里还能再有成员……
```

* 目录/文件纯粹是人类工具, 和编译没关系, 编译都声明在一起.
  * 子目录也可以直接用, 他是模块(target), 不是文件和目录限制.
* 没有编译顺序问题, 所以不存在循环依赖问题. 
  * swift的方式是, 先收集所有声明, 再做类型检查, 因此, 声明后置没有问题.
* 代码有序
  * **存储属性的初始化顺序**有运行时语义，但那是初始化器执行顺序，不是声明可见性。
  * **顶层代码**（main.swift 或 playground）是顺序执行的，但那是运行时执行顺序，不影响声明在模块内的编译期可见性。
* 构造函数是 init() 但是, 经常看不到他
  * struct可以省略, 因为有个默认的.
  * var参数是可以有默认值的, let如果有默认值就不是参数, 否则就是参数.

```swift
struct G {
    var x: Int
    var y: Int
    init(x: Int, y: Int) { self.x = x; self.y = y }
}

extension G {
    init(z: Int) { self.init(x: z, y: z) }
}
//此时2个构造器都合法
let gg = G(x: 1, y: 2) 
let g = G(z: 3)   // 等价于 G(x: 3, y: 3)
```

# 语法样例

每个样例：一段代码 + 一张表。

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
| `: Identifiable, Hashable` | 遵循这两个协议。不是父类，是"能力清单" |
| `Identifiable` | 我能提供一个 `id`。列表（ForEach）靠它区分第几行 |
| `Hashable` | 我能比较相等，能当字典的 key |
| `let 文件名: String` | 不可变属性，没有初始值 -> 构造时必须传 |
| `var id: String { 文件名 }` | 身份就是文件名（大括号里直接算，见 §12），不用 UUID |
| struct vs class | 区别在赋值行为：struct 整体复制（改 A 不影响 B），class 传同一个对象。两者都能有方法 |

### 2.1 struct 想改自己的属性：`mutating`

struct 是值类型：实例就是那堆属性本身，没有"另有一个对象在别处"。所以**改属性就等于换掉 `self`** —— 类型系统正是这么看的，不加 `mutating` 一律不许换：

```swift
struct 钱包 {
    var 余额 = 0
    func 充() { 余额 += 1 }           // ❌ error: left side of mutating operator isn't mutable: 'self' is immutable
    mutating func 充2() { 余额 += 1 } // ✓ note 说的就是它: mark method 'mutating' to make 'self' mutable
}
```

本质是 `self` 变成了 `inout`（手写出来是 `static func 充(self: inout 钱包)`）—— 改的是**调用者那个变量**，所以调用侧必须是个能变的变量：

```swift
var 钱 = 钱包(); 钱.充2()   // ✓
let 甲 = 钱包(); 甲.充2()   // ❌ cannot use mutating member on immutable value: '甲' is a 'let' constant
钱包().充2()               // ❌ cannot use mutating member on immutable value: function call returns immutable value
```

两条配套：**class 不许写** `mutating`（`'mutating' is not valid on instance methods in classes` —— 引用类型改的是对象内部，引用自己不动）；**protocol 里写 `mutating func`** = "这条要求要改 self"，于是 struct 实现必须写、class 实现不许写。enum 同理，还能在 `mutating` 里整个换：`self = .别的case`。

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

### 3.1 `inout`：把调用者的变量借给函数

参数默认是拷贝（而且是 `let` 拷贝，函数里改不了）；`inout` = 借来**调用者那个变量本身**，改了就写回去：

```swift
func 普通(_ n: Int) { n += 1 }       // ❌ 'n' is a 'let' constant
func 就地(_ n: inout Int) { n += 1 }

var x = 1
就地(&x)                             // 2   ← 外面的 x 变了
swap(&a, &b)                         // 标准库的 swap 也是 inout: 5 3
```

`&` 不是 C 的取地址，是"借出去"的标记 —— 借的必须是一块**能改的存储**（`就地(&1)` 报 `literals are not mutable`；
`let y = 1; 就地(&y)` 报 `'y' is a 'let' constant`；`就地(&(x + 1))` 报 `binary operator returns immutable value`）。
一块存储同时只能借一次（`两个(&x, &x)` → `inout arguments are not allowed to alias each other`），
也不能存起来（逃逸闭包捕获它 → `escaping closure captures 'inout' parameter 'n'`）—— 函数返回就还。

`mutating func 充()`（§2.1）就是 `self` 是 `inout`：`钱.充()` 省掉的 `&` 是语法糖，脱糖版 `钱包.充(self: &钱)` 要写。
项目里目前一个 `inout` 都没有（都是纯函数）。

---

## 4. 带默认值的闭包属性（空函数是干啥的）

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

```swift
private var 按日期排: [日记] {
    日记表.values.sorted { a, b in
        switch (DiaryNameAbbreviator.日期(a.文件名), DiaryNameAbbreviator.日期(b.文件名)) {
        case let (x?, y?): return x > y   // 两边都有日期：日期大的排前面
        case (nil, _?):    return false   // 左边没日期、右边有：左边沉底
        case (_?, nil):    return true    // 左边有、右边没：左边排前面
        default:           return a.文件名 < b.文件名  // 都没日期：按文件名排
        }
    }
}
```

| 写法 | 含义                                                         |
| :--- | :----------------------------------------------------------- |
| `x?` | 可选值非 `nil` 时匹配，把解包后的值绑定给 `x`                |
| `y?` | 同上，绑定给 `y`                                             |
| `_?` | 可选值非 `nil` 时匹配，但**不绑定名字**（`_` 表示忽略解包后的值），只关心“不是 nil” |

---

## 7. 字符串

```swift
return f.string(from: d) + " 日记"
if y == nowYear, m == nowMonth { return "本月\(day)日" }
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
| `break` | 不是用来"防穿透"的（Swift 每个 case 自动结束，没有穿透）。这里是**必须写**：case 体不能空着 —— `default:` 后面什么都不写，报 `'default' label in a 'switch' must have at least one executable statement` |

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
| `struct KeyiosApp: App` | 遵循 App 协议 = 能被系统当"一个 app"启动 |
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

泛型是"类型带参数"的机制，struct / enum / class / 函数都能带：

```swift
struct 箱子<T> { var 内容: T }                   // 泛型 struct —— Array / Dictionary / Set 就是
enum 结果<T>   { case 成功(T) }                  // 泛型 enum   —— Optional 就是
class 栈<T>    { var 项: [T] = [] }              // 泛型 class
func 取第一个<T>(_ a: [T]) -> T? { a.first }     // 泛型函数
```

泛型函数最容易踩的坑：**函数体不能空着**。这行原来是 `{ }`，`-typecheck` 说通过，真编报错：

```swift
func 取第一个<T>(_ a: [T]) -> T? { }
// swiftc -c         → error: missing return in global function expected to return 'T?'
// swiftc -typecheck → 一声不吭, 退出码 0      ← 见 §22
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

`associatedtype` = 协议里的**占位类型名**, 谁遵循谁填:

```swift
protocol 容器 { associatedtype 元素 }
struct 箱子: 容器 { typealias 元素 = Int }   // 填法一: 明写

protocol 有内容 { associatedtype 元素; var 内容: [元素] { get } }
struct 筐: 有内容 { var 内容: [Int] }        // 填法二: 从用它的地方推出来 → 元素 = Int

struct 日记: Identifiable { var id: String { 文件名 } }   // Identifiable 的 ID = String（填法二）
```

### 21.1 泛型参数 vs `associatedtype`：一对对偶，Swift 只做了半边

两个都是"占位类型"，但方向相反：**泛型是输入**（用的人给，∀），**associatedtype 是输出**（实现的人给，∃）。

下面把"声明遵循某协议的类型"简称**遵循者**（conforming type；`struct 甲: 容器` 里的 `甲` 就是）。

| | 泛型 `<T>` | `associatedtype` |
| --- | --- | --- |
| 谁选 | 用的人（调用处/字段声明处） | 实现协议的类型（写遵循处） |
| 在哪定死 | **每个使用处**各定一次，可以并存 | **每个遵循者**定一次，之后固定 |

占位符本身两边一样，**没有区别** —— `associatedtype` 也随遵循者变成不同的具体类型，不是"只有一种"：

```swift
protocol 容器 { associatedtype 元素 }
struct 甲: 容器 { typealias 元素 = Int }
struct 乙: 容器 { typealias 元素 = String }      // 各填各的

func 取<T: 容器>(_ x: T, _ e: T.元素) -> T.元素 { e }
取(甲(), 1)        // T = 甲 → T.元素 = Int
取(乙(), "x")      // T = 乙 → T.元素 = String

struct 箱子<T> { var 内容: T }
let a = 箱子(内容: 1); let b = 箱子(内容: "x")   // 箱子<Int> / 箱子<String>, 两个类型并存
extension 甲: 容器 {}                            // ❌ redundant conformance of '甲' to protocol '容器'
```

差别只剩在"谁在什么时候定死"：泛型是**每个使用处**各定一次（同一个 `箱子` 可以有无数个实例类型）；
`associatedtype` 是**每个遵循者**在声明遵循时（`struct 甲: 容器`）定一次 —— 可以 `typealias 元素 = Int` 明写，
也可以从成员的**声明类型**推出来（前面"填法二"：`var 内容: [Int]` → 元素 = Int）。
它跟"初始值"无关：类型不是一个值，没有初始值这回事 —— 必须从初始值推类型的那个是 `var 乙: some 会游泳`（见上）。

Rust 两边都有，选法一句话：**一个类型可能有多份实现 → 泛型参数；只有一份 → 关联类型**（`Iterator::Item`）。

Swift 只有 associatedtype 这半边。协议上的尖括号**也不是**泛型参数，是主关联类型（SE-0346）——
只是让存在类型能把它钉住，填的仍然是实现者：

```swift
protocol 容器<元素> { associatedtype 元素; var 内容: 元素 { get } }
let a: any 容器<Int> = 箱(内容: 1)           // ✓
let c: any 容器<String> = 箱(内容: 1)        // ❌ cannot convert value of type 'Int' to specified type 'String'
```

对偶的另一半（协议由**用的人**选参数、一个类型可以按不同参数遵循多次）Swift 没有对等物，
只能拿泛型函数 / 泛型 struct 去凑 —— 所以这两套语法看着不像一个东西的两面。

| 位置           | 写法                                                         | 意思                   |
| -------------- | ------------------------------------------------------------ | ---------------------- |
| ① **冒号后面** | `struct 青蛙: 会游泳`、`enum 蝌蚪: 会游泳`、`class 鱼: 会游泳` | 遵循                   |
| ② **泛型约束** | `func f<T: 会游泳>(_ x: T)`、`struct 箱子<T: 会游泳>`        | 约束                   |
| ③ **值的类型** | `var a: any 会游泳` / `var b: some 会游泳`                   | any和some都写得出来，但**只有 `any` 能换值**（见下） |

`any` 把 protocol 变成一个 **existential** 类型（所有遵循者共用一个）；`some 协议` 是 **opaque** 类型.

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

// 初始值不能省 —— some 的真身只能从初始值推。没初始值, 声明这一行就立不住:
var 丙: some 会游泳           // ❌ error: property declares an opaque return type, but has no
丙 = 青蛙()                   //    initializer expression from which to infer an underlying type
                             //    [#OpaqueTypeInference]

// 但初始值锁的是**类型**, 不是值 —— 值在 var 下还能原地改 (走协议自己的要求):
protocol 能充值 { var 余额: Int { get set }; mutating func 充() }
struct 钱包: 能充值 { var 余额 = 0; mutating func 充() { 余额 += 1 } }

var 戊: some 能充值 = 钱包()
戊.充(); 戊.充(); 戊.余额      // 2      ✓ 内容能改
戊 = 钱包()                   // ❌ cannot assign value of type '钱包' to type 'some 能充值'

let 己: some 能充值 = 钱包()
己.充()                      // ❌ cannot use mutating member on immutable value: '己' is a 'let' constant
                            //    note: change 'let' to 'var' to make it mutable
```

一句话：`var some P` 不是废的 —— 协议带 `{ get set }` / `mutating` 时非它不可（要改内容）；
协议只读时（多数情况，比如 View）确实写 `let` 更合适。

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

四步，别混：**静态检查 → 编译 → 链接 → 运行**。

| 停在哪一步 | 命令 | 干什么 | 产物 |
| --- | --- | --- | --- |
| 静态检查 | `swiftc -typecheck x.swift` | 语法 + 类型 | 没有 |
| 编译 | `swiftc -c x.swift` | 检查 + 生成机器码 | `x.o` |
| 链接 | `swiftc x.o -o 名字` | 把 .o 和系统库拼起来 | 可执行文件 |
| 运行 | `./名字` | 执行 | 输出 |

日常就是打包：`swiftc x.swift -o 名字` = 编译 + 链接；`swift x.swift` = 编译 + 链接 + 运行；
`swift -e 'print(6*7)'` 一行式（输出 42）；`swift repl` 交互式。
`swiftc -v` 能看到两条命令：先 `swift-frontend -frontend -c … -o a.o`，再 `clang a.o … -o 程序`（clang 负责链接）。

两条边界，分清"跑起来看界面"和"只检查能不能编"：

- 纯逻辑（字符串、数组、日期、算法）随便在终端跑
- 用到 SwiftUI / UIKit 的代码**不能在终端跑起来看界面** —— 那要模拟器，只能走项目里的 `./build.sh`。
  但"只检查能不能编"（不跑）在终端就能做 —— 注意下面 `-typecheck` 和 `-c` 的差别：

  **先记住 `-typecheck` 的坑：它不等于"能不能编"。** 它只跑到"类型检查"为止，后面（SILGen）才发现的错它不报 ——
  `missing return`、读还没赋值的变量都是这一类：

  ```swift
  // bad.swift 的全部内容
  func f() -> Int { }
  ```
  ```bash
  $ swiftc -typecheck bad.swift ; echo $?
  0                       # "没事" —— 其实编不过
  $ swiftc -c bad.swift
  bad.swift:2:19: error: missing return in global function expected to return 'Int'
  ```

  ```swift
  var x: Int
  print(x)                // swiftc -typecheck 过, -c 报: variable 'x' used before being initialized
  ```

  （§20 那个空函数体的泛型函数，就是这么漏过去的。）

  所以"检查能不能编"要用 `-c`（真编，产物是 .o，所以去临时目录跑，别在项目根拉一地）：

  ```bash
  cd /tmp && xcrun -sdk iphonesimulator swiftc -c -target arm64-apple-ios17.0-simulator \
      /Users/X/keyios/Keyios/*.swift
  ```

  实测：整份项目源码这样编**通过**，零错零警告。
  （research/ 里那几段实验用的 `-typecheck` 版更快，但别拿它当"能编"的证明。）
  不加 `-sdk iphonesimulator` 会按 macOS 编，同一份代码立刻报 8 个错 —— 全是 `'bottomBar' is unavailable in macOS`，
  也就是说挡路的是**iOS 专属的 API**，不是 SwiftUI 本身。

- 以后 dog 解析这类纯逻辑抽成 SwiftPM 包，就能 `swift test` 在终端里毫秒级验证（不用开模拟器）

---

## 23. Swift ↔ Rust 对照（为什么写着像）

"值语义 + 明确的可变性 + 独占访问"

| 事 | Rust | Swift |
| --- | --- | --- |
| 改自己要标记 | `let mut x`、`fn f(&mut self)` | `var x`、`mutating func`（§2.1） |
| 借出去改 | `&mut T`，调用 `f(&mut x)` | `inout T`，调用 `f(&x)`（§3.1） |
| 不能同时两个可变借 | 借用检查器，**全编译期** | inout 别名编不过；全局变量/类属性是**运行期炸**：`Simultaneous accesses to 0x…, but modification requires exclusive access` |
| 抽象类型 | `impl Trait` / `dyn Trait` | `some P` / `any P` —— 零开销 vs 盒子，分工一样（§21） |
| 代数数据类型 | `enum` + `match`，少一个分支编不过 | `enum` + `switch`，同（§17） |
| 可空 | `Option<T>` + `if let Some(x)` | `T?` + `if let` / `guard let`（§6） |
| 移动语义 | 默认 move，`Copy` 才复制 | 默认复制；新加的 `~Copyable` + `consuming`/`borrowing`（复制一下报 `'a' consumed more than once`） |

**真不一样的地方，一条就够：内存怎么管。** Rust 是所有权 + 生命周期，全编译期算完，运行时零开销、没有引用计数；
Swift 是值类型复制（容器写时复制）+ 引用类型 ARC **运行时**引用计数 —— 循环引用要手动 `weak`，生命周期基本不写进签名。
这条差异的直接后果就在上表第三行：**Rust 是编不过，Swift 是跑着炸**。

另外几处 Swift 明显是另一路人：有 class 和继承（Rust 故意不要）、协议能给别人的类型补遵循（retroactive conformance）、
错误处理是 `throws` 副作用而不是 `Result` 值。

（Rust 那列没实测 —— 这台机器没装 rustc，写的是它固定的语言规则；Swift 那列每条都跑过。）

---

## 24. 文档从哪查（给以后扩充本文的 AI）

| 查什么 | 去哪 | 怎么抓 |
| --- | --- | --- |
| 语言 / 语法 / 语义 | [docs.swift.org](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/)（TSPL 英文原书） | 有 JSON 后端：`docs.swift.org/swift-book/data/documentation/the-swift-programming-language/<章节>.json` |
| 官网 / 下载 / 新闻 | `www.swift.org` | |
| 官方论坛、提案讨论 | `forums.swift.org` | |
| 编译器源码、标准库、提案 | `github.com/swiftlang/swift`、`swiftlang/swift-evolution` | |
| SwiftUI / UIKit / iOS SDK | `developer.apple.com`（**只有 Apple 有**：这是平台框架，不在开源 Swift 里） | `developer.apple.com/tutorials/data/documentation/<路径>.json` |

- **没有官方中文版**：TSPL 中文是社区翻译（SwiftGG 等）。术语沿用它的：conform = 遵循，conforming type = 遵循者。
- **本机直连这些站都通**（实测 0.7–1.7s，不挂代理；代理对 Apple CDN 反而更慢）。
- Claude 的 WebFetch 工具会被安全策略挡（`Unable to verify if domain is safe`），改成 `curl --compressed` 抓。
- 规矩：往本文加结论前，先抓原文或用 swiftc 跑一遍；标"实测"的段落必须是真实输出（跑通用 `swiftc -c`，见 §22 —— `-typecheck` 会漏错）。



## 附录

* 关于类型语言的思考, 已经都放到了:类型语言log.md
