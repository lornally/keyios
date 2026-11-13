```swift
import SwiftUI //为啥要引入这个玩意? 因为app, scene, body都是swiftui提供的.
@main
struct KeyiosApp: App { //这里app是一个协议protocol 
  										//这个{花括号是接口体定义语法
    var body: some Scene { // 这个body是不是类似一个钩子或者抽象类重载? 是的.
      								// 这个{花括号是计算属性, 是getter的方法体, 返回值是scene
       WindowGroup { //这个是不是也是钩子/重载?  这里是按要求构造了一个返回值? 
         							//这里是swiftui提供的WindowGroup新建一个匿名实例对吗? 是
         							//他是body这个计算属性的返回值? swift的返回值不写return? 是, 只有一个表达式的时候可以省略return
         					//这个{花括号是个闭包
            列表v(日记表: 日记表) //这个是WindowGroup的构造函数的参数? 是的
        }
		}
}
```

## `{` 前面"紧挨着的那个东西"是什么类别

| `{` 前面紧挨着          | `{ ... }` 的含义       | 判断依据                                                     |
| :---------------------- | :--------------------- | :----------------------------------------------------------- |
| `struct KeyiosApp: App` | **类型成员体**         | 前面是**类型声明**(`struct`/`class`/`enum`/`protocol` + 名字 + 遵循) |
| `var body: some Scene`  | **计算属性 getter 体** | 前面是**变量/属性声明**(`var`/`let` + 名字 + 类型),且**没有 `=`** |
| `WindowGroup`           | **闭包(尾随闭包参数)** | 前面是一个**表达式/函数调用**,即"要调用某个函数/初始化器、或把闭包当参数传"的位置 |

```swift
struct 日记: Identifiable, Hashable {
  let 文件名: String
  let 摘要: [String]
  /// 这里就是getter只读计算属性, 现在的写法是“零成本的别名”：值仍然只有一份，就在 文件名 里。
  var id: String { 文件名 }
}
```

```swift
import Foundation //date, calendar, dataComponents, string(format:)需要 
enum 日记名f {
  //static方法是为了 日记名f.缩写("26-10-11_日记") 这种写法, 不用先 new 一个实例。
  ///1. 参数没有名字也能被正确理解. 所以可以有_, 比如参数是函数的宾语.
  ///2. 带默认值的可省略参数, 调用时必须有名字, 因此_并没有造成恶劣的影响.
  static func 缩写(
    _ fileName: String, today: Date = Date(),
    calendar: Calendar = .current
  ) -> String {
    guard let date = 日期(fileName, calendar: calendar) else {
      return 干净名(fileName)  
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
```

函数是特殊的闭包, 他们都是一级公民

| 定义（写具体实现） | 类型（描述它长什么样）                    |                     |
| :----------------- | :---------------------------------------- | ------------------- |
| 具名函数           | `func add(a: Int, b: Int) -> Int { ... }` | `(Int, Int) -> Int` |
| 闭包表达式         | `{ (a: Int, b: Int) -> Int in ... }`      | `(Int, Int) -> Int` |

Swift 里只有**一种**东西叫"可执行代码"——**函数/闭包**（Swift 官方把它们视为同一类：closure）。区别只是**书写形式**：

1. **具名函数**：`func name(...) -> T { ... }`，有名字，通常定义在类型/全局作用域
2. **闭包表达式**：`{ (params) -> T in ... }`，匿名，可以写在任何表达式位置
3. **嵌套函数**：函数里再 `func`，有名字但作用域局部

它们的**类型**都用 `(参数) -> 返回值` 这种签名描述。你代码里的 `() -> Void` 就是这个类型签名——不是定义，是"描述"。

花括号的唯一作用是: 包裹一组在运行期执行的代码.
