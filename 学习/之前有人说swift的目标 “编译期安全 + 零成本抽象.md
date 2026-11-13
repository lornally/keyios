之前有人说swift的目标: “编译期安全 + 零成本抽象"

貌似c++和rust也是这个目标, 还有其他语言有类似目标吗? 是不是只有他们三个?

**Mojo**
Thoughtworks 的技术雷达明确提到，Mojo 具备“zero-cost abstraction”特性，同时结合了 Python 语法与系统编程能力。它面向 AI 场景，目标是在保持高层抽象的同时不牺牲底层性能。

**Hylo（原名 Val）**
这个语言的设计目标写得很直接：它自称是“zero-cost abstraction language”，强调通过可变值语义和泛型编程实现“默认安全”（内存安全、类型安全、无数据竞争），同时避免隐藏开销。它明确把自己的目标与 Rust、Zig 等语言归为一类。

**Zig**
虽然 Zig 的公开表述更强调“无隐藏控制流”“无隐藏分配”和与 C 的互操作，但它的设计哲学与零成本抽象高度重叠：不用你不付费的东西，不偷偷加运行时开销。它没有把“零成本抽象”当作口号反复宣传，但实践上属于同一阵营。

**X 语言（实验性项目）**
这是一个较新的实验性语言，设计文档中专门有“零成本抽象”一节，表述为“不用的不付费”“用的付最少”“成本不隐藏”。不过它目前更像设计草案，成熟度无法与前几个相提并论。

那么这7个语言, swift, rust, c++, mojo, hylo, zig, x, 他们都是类型语言吗? 是不是都不支持字面量(字典, 数组等集合类数据结构)直接定义和表驱动?

其实我说的是js字面量和lua表驱动

**Swift**：有数组/字典字面量 `[1,2,3]`、`["a":1]`，但**不是无类型的 JS 式字面量**——字面量必须有确定的静态类型（靠上下文推断），键值类型固定。可以做“表驱动”（`let handlers: [String: () -> Void] = [...]`），但它是**强类型字典**，不是 Lua 那种任意 table。**部分符合，但不是 JS/Lua 那种“字面量即任意结构”。**

**Rust**：`vec![]` 是宏，`HashMap` 无字面量，要 `HashMap::from([...])` 或逐项插入。**最不符合**，字典字面量恰恰是它刻意不放的。

**C++**：`{1,2,3}`、`{{"a",1}}` 是初始化列表，能构造 `std::map`，也能做表驱动（`std::unordered_map<std::string, std::function<...>>`）。**语法上接近，但类型是静态指定的**，不是无类型字面量。

**Zig**：数组有 `[_]T{...}`，字典无字面量，`std.AutoHashMap` 要手工构造。**不符合**。

**Mojo**：设计上目标支持 Python 风格 `[1,2,3]`、`{"foo":1}`，且强调可做元编程/表驱动。**方向上接近，但成熟度和“任意结构字面量”程度需看具体版本。**

**X**：设计文档有 `[1,2,3]`、`{"alice":10}` 复合字面量，静态类型 + HM 推断。**语法接近 JS 字面量，但仍是静态类型。**

**Hylo**：信息不足，无法判断是否有 JS/Lua 式字面量。

字面量要么被上下文推断成确定类型（Swift/C++/X/Mojo），要么干脆不给字典字面量（Rust/Zig）。

如果是上下文推断的字面量其实从语法角度来讲就是无类型字面量的编译期实现. 就等于是实现了. 让我很惊讶, swift竟然是实现的, 看上去mojo实现的非常充分啊, 你能分别给点swift/mojo/x/hylo的相关样例代码让我尝尝咸淡吗?

```swift
// 推断为 [String: String]
var airports = ["TYO": "Tokyo", "DUB": "Dublin"]

// 推断为 [String]
var shoppingList = ["Eggs", "Milk"]

//表驱动
let handlers: [String: (Int) -> Void] = [
    "add": { print($0 + 1) },
    "sub": { print($0 - 1) }
]
handlers["add"]?(5)
```

```mojo
mylist = [1, 2, 3]           # 默认 List
mydict = {"foo": 1, "bar": 2} # 默认 Dict

fn take_inline_array(arr: InlineArray[Int, 18]): ...
take_inline_array([1, 2, 3])  # 上下文是 InlineArray，字面量就构造成它
# 他家推荐表驱动代替if/elif
```

```x
let point = { x: 1.0, y: 2.0 }
let nums  = [1, 2, 3, 4]
let map   = { "alice": 10, "bob": 20 }
```

