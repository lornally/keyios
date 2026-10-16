// ============================================================================
// 【实验: some 和 any 的尺寸 —— "some 是不是给个指针?" 不是, 反过来】
// ============================================================================
// 跑: swift research/some与any的大小.swift
//
// 实测结果:
//   some 版:  小 8 字节    大 160 字节    ← 值本身, 尺寸随内容变 (和裸值逐字节相同)
//   any  版:  小 40 字节   大 40 字节     ← 盒子, 永远 40
//   裸值:     Int 8       大 160         ← some 版和它完全一样, 零额外开销
//
// 结论:
//   * some = 值本身, 没有指针、没有盒子、没有任何额外东西
//   * any  = 才是指针那一路: 内容大到塞不进 40 字节的盒子时, 内容被放到堆上,
//            盒子里放它的地址
// ============================================================================

struct 大: Equatable {
    var a1 = 0, a2 = 0, a3 = 0, a4 = 0, a5 = 0, a6 = 0, a7 = 0, a8 = 0, a9 = 0, a10 = 0
    var a11 = 0, a12 = 0, a13 = 0, a14 = 0, a15 = 0, a16 = 0, a17 = 0, a18 = 0, a19 = 0, a20 = 0
}   // 20 个 Int = 160 字节

func 造小() -> some Equatable { 42 }      // 8 字节的东西
func 造大() -> some Equatable { 大() }    // 160 字节的东西

print("── some 版: 变量里装的就是值本身 ──")
print("小:", MemoryLayout.size(ofValue: 造小()), "字节")
print("大:", MemoryLayout.size(ofValue: 造大()), "字节")

print("\n── any 版(盒子): 不管内容多大, 尺寸都一样 ──")
let a: any Equatable = 42
let b: any Equatable = 大()
print("小:", MemoryLayout.size(ofValue: a), "字节")
print("大:", MemoryLayout.size(ofValue: b), "字节")

print("\n── 对照 ──")
print("裸 Int:", MemoryLayout.size(ofValue: 42), "| 裸 大:", MemoryLayout.size(ofValue: 大()))
