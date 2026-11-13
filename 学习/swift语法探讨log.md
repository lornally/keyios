#### 11.12

```swift
        ForEach(过滤后) { d in  //过滤后 是之前的private属性, 是一个日记数组的计算属性? d 就是[过滤后]的每个元素, foreach的单个元素, 他的语法是foreach(他们){x in, 这里x是他们的一员, 要求是他们有id
```

为啥swift用foreach in, 不用for in? 这个foreach有啥优势吗?

* 因为swift的数据映射到界面, 此时要更新其中变化的内容, foreach就是这个映射.
* swift的foreach这个玩法就和qt的widget/qml, 以及js的react很像, 但是, 我感觉最好的方案是qt的graphicview, 是我有问题吗?
* 核心是类似theme这样的能力, 如果是命令式, 则这个theme要自己抽取抽象出来, 如果是声明式, 这个能力是整体泛型架构提供的. 也就是声明式比命令式其实系统多提供了一套架构代码?
* 咱们简洁点, 你太啰嗦了, 声明式给我的感觉像是很久之前微软的vb, 他是基于面向对象搞得抽象, 也是提供了无数的方便的属性, 但是, 如果做比较复杂的的东西, 比如脑图, 写起来就不如命令式舒适.



### 11.8

```swift
let 日记表: Dictionary<String, 日记> = [...] //这个是下面的等价写法

let 日记表: [String: 日记] = [  //这里 [String: 日记] 啥意思? 日记类型的string? string自己不是类型吗?
//这里的意思是, key是string, value是日记.
    "26-10-16_日记": 日记(文件名: "26-10-16_日记",
                        摘要: ["10:12 买菜", "11:22 洗衣服", "21:00 散步"]),   

    "26-10-15_日记": 日记(文件名: "26-10-15_日记",
                        摘要: ["09:03 晨跑", "14:40 写周报", "20:15 看电影"]),
]

struct 日记: Identifiable, Hashable {
  let 文件名: String
  let 摘要: [String]
  var id: String { 文件名 } //这里为啥是var不是let?
  //这是计算属性, 不存储值, 因此用var
}


```

```swift
import SwiftUI  
@main 
struct KeyiosApp: App {  
  var body: some Scene { 
    WindowGroup {  //这个就是返回值也就是body
      列表v(日记表: 日记表)  
    }
  }
}
//app里面有一个scene这个我理解.
//scene里面必须有个Windowgroup, group里面有个view, 这个我就不理解为啥了.
//我之前用qt的graphicview体系, 他有scene和view, 没有swift的这么多玩意, 而且也没有这么多包含关系, qt是相关关系.
```

1. **`App`**：代表整个应用程序。它负责定义应用启动时应该呈现什么内容。
2. **`Scene`**：代表应用界面的一部分，其生命周期由系统管理。一个 App 可以包含多个 Scene，比如一个主窗口、一个偏好设置面板。系统会根据平台和当前状态，决定如何以及何时呈现这些 Scene。
3. **`WindowGroup`**：是最常用的一种 `Scene`。它的作用是**管理一组结构相同的窗口**。你提供的那个 `列表v`，就是创建每个窗口时使用的“模板”。

| 概念       | SwiftUI                 | Qt Graphics View                    | 关系本质                  |
| :--------- | :---------------------- | :---------------------------------- | :------------------------ |
| **顶层**   | `App`                   | 无直接对应（通常是 `QApplication`） | 应用入口                  |
| **中间层** | `Scene` / `WindowGroup` | **无直接对应**                      | 应用界面单元 / 窗口管理器 |
| **底层**   | `View`                  | `QGraphicsScene` + `QGraphicsView`  | 内容与呈现                |

既然body就是scene了, 为啥还要套上Windowgroup? 我的app有多个界面, 为啥这里就一个列表v(他是个view).

* 哦, 我理解了, Windowgroup就是body的计算属性的返回值, 也就是说他就是body, 只不过swift的写法是嵌套而不是等号. 
* Windowgroup和view也是同理, 他们之间其实是一一对应的关联关系, 只不过swift表现为包含关系, 也就是说: 多个view要多个Windowgroup
* 更准确描述: **一个 `WindowGroup` 里只放一个根 View，但那个根 View 内部可以容纳无数个 View。**

```swift
//多个view要多个Windowgroup
var body: some Scene {
    WindowGroup { 列表v(日记表: 日记表) }   // 主窗口
    Settings { 设置v() }                    // 偏好设置面板（另一个 Scene）
}
```

* 你对于嵌套的定义不对, 有花括号就是嵌套了, 他的圈复杂度就是增加了. swift有增加这个复杂度的倾向, 这是这个语言的根本性弱点.
* 因为类似body的具体值, windowgroup和根view的关系这种东西, 完全可以用不加嵌套的写法搞定, 但是, swift偏偏加了嵌套. 从这个角度看, swift集成lisp的衣钵.
* 你没有理解我说的意思的本质, 我的意思是lisp和c站在两端, 如果是c写法:

```c
//稍稍扩展了带名字空间的c
body=Windowgroup
body.根view=列表v(日记表)
```

* 而swift给我的感觉是, 他把原本oc的c部分换成了lisp范式, 他的花括号执行其实拿的是返回值, 也就是说, 他是花括号有值的概念, 这个和lisp是一致的. 你之前的分析过于死板僵化了, 没有抓住c和lisp的本质分歧
* swift本质上是一个很多语法糖的类型式lisp

```swift

struct 列表v: View {
  let 日记表: [String: 日记]
  @State private var searchText = ""  // 搜索框里打的字
  @State private var isSearching = false  // 搜索开着点底部放大镜时置 true)
  @State private var showingNewNote = false  // 新建页弹出来了
  @State private var path: [日记] = []  // 导航栈：点进详情页时往里塞一条

  private var 按日期排: [日记] { //这个也是private?
    日记表.values.sorted { a, b in
      switch (日记名f.日期(a.文件名), 日记名f.日期(b.文件名)) {
      case (let x?, let y?): return x > y
      case (nil, _?): return false  
      case (_?, nil): return true
      default: return a.文件名 < b.文件名
      }
    }
  }

  private var 过滤后: [日记] {
    guard isSearching, !searchText.isEmpty else { return 按日期排 }
    return 按日期排.filter { d in
      d.文件名.contains(searchText)  // 磁盘文件名
        || 日记名f.缩写(d.文件名).contains(searchText)  // 缩减后的名字
        || d.摘要.contains { $0.contains(searchText) }  // 任一条摘要
    }
  }

  //这里body就是一个NavigationStack, 这个NavigationStack和ZStack啥关系. 下面的.searchable是zstack的方法调用吗?
  //body的根是NavigationStack, NavigationStack的根是ZStack
  var body: some View {
    NavigationStack(path: $path) {
      ZStack {
        Theme.background.ignoresSafeArea()
        listContent
      }

      .searchable(text: $searchText, isPresented: $isSearching, prompt: "搜索日记")
      .modifier(MinimizedSearchField())

      .navigationDestination(for: 日记.self) { d in
        脑图V(日记: d)
      }

      .sheet(isPresented: $showingNewNote) {
        新建V()
      }

      .toolbar(.hidden, for: .navigationBar)

      .toolbar {
        Bar(
          onSearch: { isSearching = true },
          onNew: { showingNewNote = true }
        )
      }
      .tint(Theme.accent)
    }
    .preferredColorScheme(.dark)  
  }

  private var listContent: some View {
    ScrollView {  //滚动?
      LazyVStack(spacing: 8) { //懒惰的栈, 只加载展示内容
        ForEach(过滤后) { d in  //过滤后 是之前的private属性, 是一个日记数组的计算属性? d 就是[过滤后]的每个元素, foreach的单个元素, 他的语法是foreach(他们){x in, 这里x是他们的一员, 要求是他们有id
          单行V(日记: d)
            .contentShape(Capsule())  // 让整条胶囊都可点（默认只有文字可点）
            .onTapGesture { path.append(d) }
        }
      }
      .padding(.horizontal, 12)
      .padding(.top, 8)
      .padding(.bottom, 8)  // 底部条的避让由系统自己处理，这里只要一点余量
    }
  }
}
private struct MinimizedSearchField: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.searchToolbarBehavior(.minimize)
    } else {
      content  
    }
  }
}
```

````swift
NavigationStack(path: $path) {
  ZStack { ... }
  .searchable(...)          // ← 作用在 ZStack 上
  .modifier(...)
  .navigationDestination(...)
  .sheet(...)
  .toolbar(.hidden, ...)
  .toolbar { Bar(...) }
  .tint(...)
}
````

* 所以整理一下这就是一个链式调用? :   ZStack { ... }.searchable(...).modifier(...)
* body的根是NavigationStack, NavigationStack的根是ZStack, 那么我请问, 他们都是这种单个的结构吗? 非根元素可以有吗? 

表格中你说的不对, `多语句会编译错`, 并不会编译报错, 而是会直接组装为truple view.

| 位置                             | 是否只能一个       | 说明                                                         |
| :------------------------------- | :----------------- | :----------------------------------------------------------- |
| `body` 的返回值                  | **类型上是单一的** | 多条语句**不报错**，由 `@ViewBuilder` 合成一个 `TupleView`；混合多类型 `return` 或缺少 `@ViewBuilder` 才报错 |
| `NavigationStack { }` 闭包       | **类型上是单一的** | 同上，`@ViewBuilder` 合成；多条子视图能编译但布局语义通常不合适 |
| `ZStack { }` / `VStack { }` 内部 | 否，可多个         | 容器内部就是设计来装多个子视图的                             |
| `ForEach` 元素                   | 否，可多个         | 本身算一个视图，内部展开                                     |

swift这层层叠叠的架构真的讨厌, 没啥意义啊, 感觉和java好像啊, view里面有body, body有NavigationStack, NavigationStack有zstack, 我之前用qt的, 他的graphicview的每个元素都是有意义的, 到了swift, 感觉他就是在俄罗斯套娃.

你的分析偏了, 链式调用没啥问题, 问题就是他分了view.body, NavigationStack, zstack, 并且他们之间都是构造关系. 我用qt, 只要view和scene, 然后就可以布置内容了,  而swift实际上是 App.body=scene, scene的根是一个Windowgroup, Windowgroup的根是view, view.body=NavigationStack, NavigationStack的根是zstack. 这不是有病吗? 如果我手写界面, 这根本写不出来啊, 必须辅助代码生成才行, 这是我说他像java的原因, java也是一堆辅助性代码, 没有代码生成根本搞不定, 不像是c或者qt或者python那样, 我根本不可能手写出界面来.

#### 11.4

* 11:31

```swift
// 这里是声明一个struct BarButton. 花括号内部是这个BarButton的定义, 这个struct的类型是ToolbarContent
// <label:view> 是struct内部元素的类型吗? 不是的, 这个是泛型参数, label参数必须遵守view协议
private struct BarButton<Label: View>: ToolbarContent {
  @ViewBuilder var label: () -> Label
  //@ViewBuilder 这是啥? 这个label属性为啥没有默认值? 是实例化的时候传进来吗? 是的
  //他是参数属性结果构造器, result builder/parameter attribute, 也就是传给label的时候可以有多个view.
  var body: some ToolbarContent {
    //body是一个计算属性吗?  是的.
    //他的返回值是下面的ToolbarItem和可选地ToolbarSpacer吗? 是的.
    //虽然 body 的返回类型写的是 some ToolbarContent（一个不透明类型），但 SwiftUI 为 body 隐式应用了结果构建器（类似 @ToolbarContentBuilder），它会将这两条语句自动组合成一个单一的 ToolbarContent 值返回。
    ToolbarItem(placement: .bottomBar, content: label)
    if #available(iOS 26.0, *) {
      ToolbarSpacer(.fixed, placement: .bottomBar)
    }
  }
}

// 既然`@ViewBuilder` 让这个闭包可以包含多个视图表达式, 你能给我一个构建barbutton的例子吗?

//实用例子, 按钮同时有图标、文字和间距
BarButton { //这个闭包就是label属性的内容, 
    // 这里是 @ViewBuilder 闭包，可以写多条视图表达式
    Label("分享", systemImage: "square.and.arrow.up")
    Text("导出")
        .font(.caption)
        .foregroundStyle(.secondary)
  	//@ViewBuilder 会把它们组合成一个 TupleView
}
//@ViewBuilder把多个view类型的label组合成什么view这件事是全自动, 有时候是TupleView, 有时候是hstack/vstack吗? 不, @ViewBuilder 的行为是确定的，它几乎总是将多个视图组合成 TupleView
// @ViewBuilder有如下特性:
// 1. 参数不能超过10个.
// 2. 单个视图直接返回, 不会包装为tupleview
// 3. 条件分支：如果闭包里包含 if / switch 语句，@ViewBuilder 会使用 _ConditionalContent 或 AnyView 等机制来统一返回类型

```

看上去swift为了避免java那种单根架构(其实也类似万能指针了), 费尽了心思.

### Swift 的替代方案：不设根，用协议和泛型

Swift 没有统一的基类（`NSObject` 只是 Objective-C 桥接的产物，不是 Swift 的根基）。它用几样东西替代了单根架构的「统一」职能：

1. **协议（protocol）**：定义「能做什么」，而不是「是什么」。`View`、`Equatable`、`Codable` 都是协议，任何类型都可以按需遵循，不需要共享祖先。
2. **泛型 + 协议约束**：`<Label: View>` 这种写法，让「任何遵循 `View` 的类型」都能在编译期被精确约束，而不需要退化成 `Any` 或基类指针。
3. **值类型（struct/enum）**：天然是「叶子」类型，不需要继承，天然支持值语义和写时复制。
4. **不透明返回类型 `some View`**：调用者知道「返回了某个具体遵循 `View` 的类型」，但不需要知道具体是什么，也不需要存在一个统一的基类来容纳它。

代价：

- **类型签名爆炸**：`some View`、`TupleView<(A, B)>`、`_ConditionalContent<TrueContent, FalseContent>` 这些类型对开发者不透明，报错信息常常难以阅读。
- **编译时间**：泛型和结果构建器的类型推断很重，SwiftUI 视图复杂时编译慢是出了名的。
- **学习曲线**：要理解 `@ViewBuilder` 为什么这样工作，得先理解协议、泛型、结果构建器、不透明类型这一整套。

收益：

- **零成本抽象**：没有基类指针、没有装箱、没有运行时类型擦除（除非你主动用 `AnyView`）。
- **编译期类型安全**：`TupleView` 里每个元素的类型都是精确已知的，SwiftUI 的 diff 算法可以据此做高效更新。
- **值语义**：视图是 struct，天然不可变、可比较、易于推理。



```swift
struct Bar: ToolbarContent {
  
  //这两个方法都给了默认值{}, 但是未来调用bar的时候还能传参数进来对吗? 为什么?
  var onSearch: () -> Void = {}
  var onNew: () -> Void = {}
	
  //这里categories是个局部变量吗? 不是局部变量，是实例存储属性（instance stored property）。
  private let categories = ["待办", "持续", "暂缓", "完成", "全部"]
  var body: some ToolbarContent {

    // body的条件返回值
    if #available(iOS 26.0, *) {
      DefaultToolbarItem(kind: .search, placement: .bottomBar)
      ToolbarSpacer(.fixed, placement: .bottomBar)
    } else {
      BarButton {
        Button(action: onSearch) { Image(systemName: "magnifyingglass") }
      }
    }

    // body的返回值2
    BarButton {
      Button(action: onNew) { Image(systemName: "plus") }
    }

    // body的返回值的第三部分
		//foreach是个函数, 这是花括号是他的闭包参数吗? foreach是一个结构体, 所以尾部的花括号是尾随闭包, 给的是参数content
    ForEach(categories, id: \.self) { name in //这个name in是个什么结果? 这个等于给了闭包参数. 
    //所以这里就是把category的每一个作为name传给button做参数, 搞出多个button, 神啊, 这语法真绕.
      BarButton {
        Button(name) {}  
      }
    }
  }
}
```

### 1. 给了默认值 `{}`，调用时还能传参数吗？为什么？

**能传。** 原因是 Swift 为结构体自动生成的**成员逐一初始化器（memberwise initializer）**。

对于一个没有自定义 `init` 的 `struct`，编译器会自动生成一个 init，参数就是所有**存储属性**，参数名等于属性名。规则是：

- **`var` 且有默认值** → 该参数出现在 init 中，**并且带同样的默认值**。所以既可以省略，也可以显式传入。
- **`let` 且有默认值** → 该属性被视为已初始化完成，**不会出现在** memberwise init 的参数里，外部无法再设置。

```swift
Bar()                                                    // 两个闭包都用默认的 {}
Bar(onSearch: { print("搜索") })                          // 只传 onSearch
Bar(onNew: { print("新建") })                             // 只传 onNew（标签顺序可跳）
Bar(onSearch: { ... }, onNew: { ... })                   // 两个都传
// Bar(categories: [...])   ❌ 编译错误，categories 不在 init 参数里
```



* 所以这里就是把category的每一个作为name传给button做参数, 搞出多个button, 神啊, 这语法真绕.
* 这玩意真没必要, lua的表驱动不是挺好的吗? 再差用js的字面量也行啊. swift有毛病.

```lua
# lua
local buttons = {
  { action = "search", icon = "magnifyingglass" },
  { action = "new", icon = "plus" },
  { action = "done", icon = "checkmark" }
}

for _, btn in ipairs(buttons) do
  create_button(btn.action, btn.icon)
end
```

```js
//js
const buttons = [
  { action: "search", icon: "magnifyingglass" },
  { action: "new", icon: "plus" }
];

buttons.map(btn => <BarButton onClick={btn.action} icon={btn.icon} />);
```

Swift 选择了“编译期安全 + 零成本抽象”,  SwiftUI 的设计目标极其苛刻：**零成本抽象、编译期类型安全、极致的 diff 性能**。为了达到这个目标，它拒绝在运行时做任何“动态”的事情，于是只能在**编译期**把类型系统玩出花来。



1. 编译语言比如c/swift/rust/haskell他们相对于解释语言js/ruby/python/list的运行期优势, 是不是就是寻址优势, 他们的寻址类似数组的直接偏移量寻址, 而解释语言的寻址类似map的间接寻址? swift相对于oc也有运行优势, 在哪里? 这些语言里面是不是c/swift/rust/c++是最为性能怪兽? 我听说go/oc都要比他们慢一些?

寻址优势只是**最表层**的一环。编译型语言真正的性能怪兽之处还在于：

- **无运行时类型检查**：类型在编译期已确定，不需要在运行时反复验证。
- **内联与优化**：编译器可以将小函数内联展开，消除调用开销，进行循环优化等。
- **栈分配与值语义**：像 Swift 的 `struct` 可以直接在栈上分配，避免了堆分配和引用计数的开销。

Swift 比 OC 快的核心，在于**从“动态消息派发”转向了“静态编译优化”**。

- **消息派发机制不同**：OC 的方法调用默认是**动态消息派发（objc_msgSend）**，每次调用都要在运行时查找方法实现，无法被编译器内联。Swift 则大量使用**静态派发和直接函数调用**，编译器可以充分优化。
- **值类型与栈分配**：Swift 的 `struct`、`enum` 是值类型，可以栈分配，避免了堆内存管理和引用计数的开销，尤其在处理大量数据时优势明显。
- **编译期检查前移**：Swift 的强类型和 `Optional` 机制把大量潜在错误拦截在编译期，减少了运行时的类型检查和空指针判断开销。

### 🐉 性能怪兽的第一梯队：C / C++ / Rust / Swift

你听说的没错，这几位基本就是系统级性能的第一梯队。

- **C/C++** 是传统王者，提供极致的手动内存控制，没有运行时开销（如 GC），编译器优化极其成熟。
- **Rust** 凭借“零成本抽象”达到了**接近 C/C++ 的运行时性能**，同时通过所有权系统在编译期保证内存安全，无需 GC。
- **Swift** 同样经过 LLVM 的 AOT 编译和深度优化，在数值计算、UI 逻辑等场景下性能与第一梯队相当，尤其在利用值类型时效率很高。

### 🐢 Go / OC 为什么相对慢一些？

- **Go** 的性能瓶颈主要来自**垃圾回收（GC）**。GC 会带来 CPU 开销和不可预测的停顿（长尾延迟），这在延迟敏感的场景中是劣势。此外，Go 在 SIMD（单指令多数据流）等底层优化生态上也不如 C/C++/Rust 成熟。
- **Objective-C** 的“慢”则是相对于上述顶级梯队而言。其动态消息派发的开销在 Swift 的静态优化面前成为了性能负担。

1. 编译为llvm的语言有哪些? 这些语言是否能通用/混用, 类似python和c那样混用? 比如我用rust写原生的swift的ios代码, 可以吗?

### ⚙️ LLVM 语言版图：同后端 ≠ 可自动混用

LLVM 是一个编译器基础设施，许多语言将其作为后端。使用 LLVM 作为前端或编译器的语言包括 **C/C++（通过 Clang）、Objective-C、Swift、Rust、Haskell、Kotlin、Ruby、Python（部分实现）、Julia、Scala、D、Zig** 等。

**但共用 LLVM 后端，绝不意味着这些语言可以像 Python 和 C 那样无缝混用。**

LLVM 只是“翻译”环节，各语言的**运行时环境（Runtime）** 是独立的——它们有各自的内存管理方式（ARC / 所有权 / GC）、对象模型和标准库。跨语言调用必须通过**FFI（外部函数接口）** 在边界上进行转换，不能直接“插进去就用”。

llvm中解释型语言多吗? rn是可以编译为ios app的, 他是什么原理? 通过llvm了吗?

* 解释语言通过解释器运行, 只是用llvm提供了运行环境解释器或者jit解释器
* rn js->某个字节码->字节码虚拟机执行

| 语言      | 编译类型                     | 编译目标              | 关键特征                                                     |
| :-------- | :--------------------------- | :-------------------- | :----------------------------------------------------------- |
| **Scala** | AOT 编译（传统）             | JVM 字节码 / 本机代码 | 静态类型，编译成 `.class` 文件在 JVM 上运行，也可通过 Scala Native 直接编译为本机可执行文件 |
| **D**     | AOT 编译（传统）             | 本机机器码            | 静态类型，**明确不是**解释型语言，直接编译为原生代码，无虚拟机 |
| **Zig**   | AOT 编译（传统）             | 本机机器码            | 静态类型，系统编程语言，设计目标就是替代 C，直接编译为原生可执行文件 |
| **Julia** | **JIT 编译为主**（可选 AOT） | 本机机器码            | **动态语言**，代码在**运行时**通过 LLVM 即时编译为机器码，也可选提前编译 |

### 🔍 为什么 Julia 是个“特例”？

你之前了解过“编译型 vs. 解释型”的二分法，Julia 恰好打破了这种简单的分类。

Julia 是**动态语言**（像 Python/Ruby），但它**没有解释器**。它的代码默认在执行时通过 LLVM **即时编译（JIT）** 成本机机器码再运行。社区甚至称其为 **“just-ahead-of-time”（JAOT）** 编译，因为 Julia 会在函数被调用前编译它。所以，它兼具了动态语言的交互性和接近 C 的性能，但本质上**依然走的是编译路线，而非解释执行**。

zig介绍一下, 他要替代c, 好大的口气啊.

语言分类:

* 动态语言/静态语言
* 编译语言/解释语言

有没有swift的playground? 有很多:

1. xcode有
2. app store有单独的playground
3. https://swiftfiddle.com/
4. https://online.swiftplayground.run/



swift如果要把一个int赋值给string. 是不是要显式类型转换? 要

int和float也要显式转换吗? 要, 并且四则运算也要同类型.

他完全不考虑现实情况的啊, 我很难想象整数除法的用处.

# 你的吐槽很合理，但整数除法其实有它明确的用途

先共情一下：从"数学直觉"看，`7 / 2 = 3` 确实反直觉，初学者踩坑无数。但 Swift（以及 C、Java、Go、Rust 等）保留整数除法，不是偷懒，而是有现实理由的。

## 1. 整数除法是"整除/取商"，不是"算比例"

`7 / 2` 在整数语境下问的不是"7 是 2 的几倍"，而是"**7 里面能完整装下几个 2**"——答案是 3 个，剩 1 个（余数用 `%` 拿）。

```swift
let groups = 7 / 2    // 能分成 3 个完整组
let rest = 7 % 2      // 剩 1 个
```

这类"分页、分组、索引计算"到处都是：

```swift
let pageCount = totalItems / pageSize      // 需要几页
let page = index / pageSize                // 第几条属于第几页
let row = index / columns                  // 网格里的行号
let mid = (low + high) / 2                 // 二分查找取中点
```

## 2. 索引和内存地址必须是整数

数组下标、循环计数、内存偏移、位运算，本质上都是整数运算。这里**根本不存在小数**，用浮点反而危险：

```swift
for i in 0..<array.count { ... }   // count 是 Int
array[i / 2]                       // 下标必须是 Int
```

如果 `i / 2` 返回 `3.5`，你没法用它当下标，还得再转回来——更麻烦。

## 3. 浮点运算有精度问题，不能随便用于"计数"

```swift
var count = 0
count += 0.1   // 0.1 在二进制里无法精确表示
// 多次累加后可能出现 0.30000000000000004
```

所以**计数、序号、金额（以分为单位存 Int）** 这类场景故意用整数，避免浮点误差。整数除法保证结果精确、可预测。

## 4. 性能与位运算

整数除法在底层是 CPU 的原生指令，快且确定；浮点除法更慢，还涉及舍入模式。位运算（`>>`、`&`、`|`）也只对整数有意义，而 `x / 2` 对非负整数等价于 `x >> 1`——这是大量底层代码的常用手法。

## 5. 类型安全：不悄悄改变类型

Swift 的设计哲学是"**不替你做可能出错的隐式决定**"。如果 `7 / 2` 自动变 `3.5`，返回类型就从 `Int` 变成 `Double`，类型系统会乱，而且你原本期望的整数结果反而丢了。让你显式选择：

```swift
7 / 2              // 3      —— 我要整除
Double(7) / 2      // 3.5    —— 我要小数
7.0 / 2.0          // 3.5    —— 同上
```

## 那"现实中的比例计算"怎么办？

确实，很多业务场景你要的是小数。Swift 的答案是：**明确表达意图**。

```swift
let ratio = Double(a) / Double(b)     // 要比例就转 Double
let percent = Double(done) / Double(total) * 100
```

或者用专门的取整 API 让意图清晰：

```swift
7.0 / 2.0                    // 3.5
(7.0 / 2.0).rounded()        // 4.0  四舍五入
Double(7) / Double(2)        // 3.5
```

## 反过来想：如果整数除法自动变小数会怎样

假设 `let x = 7 / 2` 得到 `3.5`（Double），那：

```swift
let mid = (low + high) / 2   // 变成 Double，不能做数组下标
array[mid]                   // ❌ 编译错误
let page = index / 10        // Double，页码变小数，逻辑全乱
```

**每个需要整数结果的地方都要再 `Int(...)` 转回来**，而且转换可能截断出错。所以"整数/整数=整数"反而是更常用、更安全的默认。

## 小结

| 场景                                 | 该用                               |
| ------------------------------------ | ---------------------------------- |
| 分页、分组、索引、循环、计数、位运算 | **整数除法**（`/`）                |
| 比例、平均值、科学计算、金额小数     | **浮点除法**（转 `Double` 后 `/`） |

整数除法不是"不考虑现实"，而是**现实里大量计算本来就要求整数结果**，且不能有浮点误差。Swift 只是把"你要哪种除法"这个决定权明确交给你，代价是初学时多点转换代码。习惯之后，这种"显式"反而能帮你避开很多隐蔽的精度 bug。





swift和oc在性能上的最大区别就是swift的函数是静态派发/直接调用的, 而oc是动态派发, 我很疑惑, 为啥oc要动态派发函数呢? 函数这个玩意不是声明之后就固定了吗? 为啥要动态? 而且即便把他改成静态, 也是不复杂的事情吧? 为啥swift搞了那么一大堆语法出来? 话说c本身的函数派发是静态的吧?

Swift 的设计目标之一，就是**在保留 Objective-C 互操作能力的同时，把“默认性能”提上来**。它没有简单地“把 Objective-C 改成静态”，而是引入了一套更复杂的类型系统和派发策略，让编译器能根据上下文选择最合适的方式：

- **静态派发**：用于 `struct`、`enum`、`final` 类的方法，以及全局函数。编译器直接调用，甚至内联。
- **虚表派发**：用于普通类的方法。通过类似 C++ 的虚函数表查找，比 Objective-C 的 `objc_msgSend` 快，但比静态慢。
- **动态派发**：仅用于需要 Objective-C 运行时特性的场景，比如标记了 `@objc` 或 `dynamic` 的方法、继承自 `NSObject` 的类等。



纯属没事找病.

