# Rust 尝鲜案例：从"能跑"到"跑得爽"

下面我按 **从易到难** 给你几个带详细注释的小例子，覆盖 Rust 最核心的几个卖点。每个都能直接 `cargo run` 跑起来。

---

## 案例 1：所有权 + 借用（"不需要 GC"的本质）

Rust 不靠 GC，靠**编译期所有权检查**。看这段：

```rust
fn main() {
    // String 是堆上分配的，拥有所有权
    let s1 = String::from("hello");

    // 把所有权"移动"(move)给 s2，此时 s1 失效
    let s2 = s1;

    // println!("{}", s1); // ❌ 编译错误：s1 已被移走
    println!("{}", s2);    // ✅ 只有 s2 能用

    // 借用(borrow)：不转移所有权，只是临时引用
    let len = calculate_length(&s2); // 传引用，s2 仍然可用
    println!("'{}' 的长度是 {}", s2, len);

    // 可变借用：同一时刻只能有一个可变借用，防止数据竞争
    let mut s3 = String::from("world");
    change(&mut s3);
    println!("{}", s3);
}

fn calculate_length(s: &String) -> usize { // & 表示借用，不拿走所有权
    s.len()
} // s 离开作用域，但因为只是借用，原主人不受影响

fn change(s: &mut String) { // &mut 可变借用
    s.push_str("!!!");
}
```

**爽点**：`s1 = s2` 之后再用 `s1` 是**编译错误**，而不是运行时空指针。内存释放时机由编译器静态推导，零运行时开销。

---

## 案例 2：无畏并发（编译期杜绝数据竞争）

这是 Rust 最"香"的地方——**数据竞争在编译期就过不了**。

```rust
use std::sync::{Arc, Mutex};
use std::thread;

fn main() {
    // Arc = 原子引用计数，多线程共享所有权
    // Mutex = 互斥锁，保护内部数据
    let counter = Arc::new(Mutex::new(0));
    let mut handles = vec![];

    for _ in 0..10 {
        let counter = Arc::clone(&counter); // 每个线程持有一份"共享所有权"
        let handle = thread::spawn(move || { // move：把 counter 移进闭包
            let mut num = counter.lock().unwrap(); // 加锁，返回 MutexGuard
            *num += 1;
        }); // 锁在这里自动释放（RAII，作用域结束 Drop）
        handles.push(handle);
    }

    for h in handles {
        h.join().unwrap(); // 等所有线程结束
    }

    println!("最终计数: {}", *counter.lock().unwrap()); // 应该是 10
}
```

**对比**：C++/Java 里这种代码写错了是**运行时随机崩溃**；Rust 里如果忘加 `Mutex` 直接共享可变引用，**编译根本通不过**——编译器会告诉你"`*mut` 无法跨线程共享"。

---

## 案例 3：枚举 + 模式匹配（"语义明确"）

Rust 的 `enum` 是**代数数据类型**，能把非法状态排除在外。

```rust
// 一个"订单状态"：每个变体可以携带不同数据
#[derive(Debug)]
enum OrderState {
    Pending,
    Paid { amount: u64 },       // 带字段
    Shipped(String),            // 带一个值
    Cancelled { reason: String },
}

fn describe(state: &OrderState) -> String {
    // match 必须穷尽所有分支，漏一个编译器报错
    match state {
        OrderState::Pending => "等待支付".to_string(),
        OrderState::Paid { amount } => format!("已支付 {} 元", amount),
        OrderState::Shipped(tracking) => format!("已发货，单号 {}", tracking),
        OrderState::Cancelled { reason } => format!("已取消：{}", reason),
    }
}

fn main() {
    let states = vec![
        OrderState::Pending,
        OrderState::Paid { amount: 99 },
        OrderState::Shipped("SF123456".into()),
        OrderState::Cancelled { reason: "用户后悔".into() },
    ];
    for s in &states {
        println!("{:?} => {}", s, describe(s));
    }
}
```

**爽点**：`Option<T>`、`Result<T, E>` 也是枚举，配合 `match`/`?` 让你**不可能忘处理"空"和"错误"**，比 Java 的 `NullPointerException` 和 Go 的 `if err != nil` 都明确。

---

## 案例 4：零成本抽象 + 迭代器（速度快的来源）

Rust 的迭代器链会被编译器优化成和手写循环**几乎一样快的机器码**。

```rust
fn main() {
    let nums = vec![1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    // 链式调用：过滤偶数 → 平方 → 求和
    // 全程无堆分配、无虚函数调用，编译后就是一条紧凑的循环
    let sum: i32 = nums.iter()
        .filter(|&&x| x % 2 == 0) // 只留偶数
        .map(|&x| x * x)          // 平方
        .sum();                   // 求和

    println!("偶数平方和 = {}", sum); // 4+16+36+64+100 = 220
}
```

**为什么快**：`filter`/`map` 是**内联的**，闭包会被单态化（monomorphization）成具体类型，没有动态派发开销。benchmark 里这种链式写法通常和 for 循环持平甚至更快。

---

## 案例 5：错误处理（`?` 运算符）

```rust
use std::fs;
use std::io;

// 返回 Result：要么 Ok(内容)，要么 Err(io::Error)
fn read_file_len(path: &str) -> Result<usize, io::Error> {
    let content = fs::read_to_string(path)?; // ? = 出错就提前返回 Err
    Ok(content.len())
}

fn main() {
    match read_file_len("Cargo.toml") {
        Ok(len) => println!("文件长度: {} 字节", len),
        Err(e) => println!("读取失败: {}", e),
    }
}
```

**对比**：没有异常机制（异常在 Rust 里只用于 panic），错误是**类型系统的一部分**，`?` 让你写起来和 Go 的 `if err != nil` 一样直接，但不会漏处理。

---

## 快速上手建议

```bash
# 装 Rust（一条命令）
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 建项目
cargo new playrust && cd playrust
# 把上面任意代码贴进 src/main.rs
cargo run
```

**建议照着案例改坏它**——比如删掉 `Mutex`、在 move 后用 `s1`、match 少写一个分支——看编译器的报错。Rust 的报错信息本身就是最好的教学，能让你直接感受到"语义明确"到底明确在哪。

想深入哪块（async、trait、生命周期标注、unsafe）我可以再给对应案例。