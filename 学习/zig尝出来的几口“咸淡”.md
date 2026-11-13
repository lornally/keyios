好，来一段能跑、五脏俱全的 Zig，重点不是炫技，而是让你尝出 Zig 的“味道”：**显式分配器、错误是值、comptime 泛型、defer 收尾、可选类型无隐式空指针**。

> 版本提示：下面代码按 Zig 0.14/0.15 附近的写法，`ArrayList` 和 `GeneralPurposeAllocator` 在更新版本里有改名/改 API，但**语义和风格不变**。

```zig
const std = @import("std");                      // 导入标准库，Zig 没有预导入，一切显式

// comptime 泛型函数：T 是类型参数，在编译期确定，不产生运行时泛型开销
// comptime 关键字表示“这个参数必须在编译期已知”，类似于 C 的宏，但类型安全
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;                 // if 是表达式，直接返回值，没有三元运算符
}

// 结构体定义，类似 C 的 struct，但可以带方法
const Task = struct {
    title: []const u8,                         // 切片：指针 + 长度，不是以 \0 结尾的 C 字符串
    done: bool,

    // 方法：第一个参数是 self，这里用 *Task（可变指针）因为要修改字段
    fn markDone(self: *Task) void {
        self.done = true;                      // 通过指针修改原对象，不是副本
    }
};

// main 返回 !void：错误联合类型，表示“可能失败，失败时返回任意 error”
pub fn main() !void {
    // 显式分配器：Zig 没有全局 malloc，需要内存的函数必须传入 allocator
    // GeneralPurposeAllocator 是调试友好的分配器，能检测泄漏和 UAF
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();                    // defer：作用域退出时执行，保证清理
    const allocator = gpa.allocator();         // 取出接口，类型是 std.mem.Allocator

    // 动态数组，必须显式传 allocator，对比 C++ 的 std::vector 隐式用全局分配器
    var tasks = std.ArrayList(Task).init(allocator);
    defer tasks.deinit();                      // 退出时释放底层内存，不需要手动 free

    // try：如果 append 返回错误，直接向上传播，等价于 catch |e| return e
    // .{ ... } 是匿名结构体字面量，字段类型由上下文推断
    try tasks.append(.{ .title = "学习 Zig", .done = false });
    try tasks.append(.{ .title = "写代码", .done = false });

    // for 遍历，|*task| 取指针，这样 markDone 能修改原元素；|task| 则是值拷贝
    for (tasks.items) |*task| {
        task.markDone();
        // std.debug.print 是编译期格式检查的打印，{} 是默认格式，{s} 是字符串
        std.debug.print("{s}: {}\n", .{ task.title, task.done });
    }

    // 调用 comptime 泛型函数，T 被推断为 u32，生成一份专用于 u32 的代码
    const m = max(u32, 3, 7);
    std.debug.print("max = {}\n", .{m});

    // 可选类型：?u32 表示“要么是 u32，要么是 null”，没有隐式空指针
    const maybe: ?u32 = null;
    // if (maybe) |v| 是“捕获”语法，只有非 null 时才进入分支，v 是非可选的 u32
    if (maybe) |v| {
        std.debug.print("got {}\n", .{v});
    } else {
        std.debug.print("null\n", .{});
    }

    // 错误处理：catch 捕获错误，|err| 拿到错误值，这里打印后提前 return
    // 注意：divide 返回 !u32，调用方必须处理，不能像 C 那样忽略返回码
    const result = divide(10, 0) catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    _ = result;                                // _ = 显式丢弃值，Zig 不允许静默忽略返回值
}

// 返回 !u32：错误联合类型，成功返回 u32，失败返回某个 error
fn divide(a: u32, b: u32) !u32 {
    if (b == 0) return error.DivisionByZero;   // 错误是值，不是异常，不需要 try/catch 栈展开
    return a / b;
}
```

### 尝出来的几口“咸淡”

- **`defer` 代替 goto cleanup**：C 里手动 `free` 容易漏，Zig 用 `defer` 在作用域退出时自动执行，且可以叠加多个，逆序执行。`errdefer` 还能只在出错时执行。
- **错误是值，不是异常**：`!T` 是类型系统的一部分，调用方**必须**用 `try` 或 `catch` 处理，否则编译不过。这消灭了 C 里“忘记检查返回值”的经典 bug。
- **`comptime` 是类型安全的宏**：`max(comptime T: type, ...)` 在编译期展开，生成的代码和手写 `u32` 版本一样快，但没有 C 宏的文本替换陷阱。
- **切片 `[]const u8`**：自带长度，不用 `strlen`，也不怕忘记 `\0`。Zig 里字符串就是字节切片，没有隐藏的终止符约定。
- **`_ =` 强制显式丢弃**：Zig 不允许静默忽略返回值，`_ = result` 是在说“我知道这里有个值，我故意不要”。
- **`|*task|` vs `|task|`**：前者拿指针能改原元素，后者是值拷贝。Zig 不隐藏“这是拷贝还是引用”，你必须自己写清楚。

### 和 C 对照一下“口气”

| C 的坑                 | Zig 的对应                        |
| ---------------------- | --------------------------------- |
| `malloc/free` 隐式全局 | 显式 `Allocator` 参数，调用点可见 |
| 返回码靠自觉检查       | `!T` 强制处理                     |
| 宏文本替换             | `comptime` 编译期执行语言代码     |
| `char*` + `\0`         | `[]const u8` 自带长度             |
| `goto cleanup`         | `defer` / `errdefer`              |
| 隐式类型转换           | 基本禁止，必须显式 `@intCast` 等  |

所以 Zig 的“口气大”，是因为它**在 C 的同一性能层级上，把 C 的每个经典陷阱都用语言机制堵死了**，而且不引入 GC、不引入运行时、不引入隐藏控制流。代价就是写起来比 C 啰嗦一点——每个分配器、每个错误、每个丢弃的值，都得你亲手写明白。