// ============================================================================
// 【实验: 类型清单 —— actor / 元组和函数不能符合协议 / any 协议是什么】
// ============================================================================
// 跑: swift research/类型清单.swift
//
// 实测结果:
//   1. actor 建得出, 是引用类型 (=== 是同一份), 也能符合协议
//      → 造类型的关键字 5 个: struct / enum / class / actor / protocol
//   2. 元组和函数不能符合协议 → some 协议 背后只剩 struct / enum / class / actor
//   3. any 协议 / Any 是表里单列的一行 (existential), 大小定长:
//        Any            = 32 字节 (= 不要求任何东西的 any)
//        any 会游泳      = 40 字节 (多挂一个协议多 8)
//        any 只会游(限 class) = 16 字节
//      对照, 随内容变: 元组(Int,Int)=16, 元组三个=24, 函数=16
//   4. any 变量自己造不出来: Any() 编译不过
//   5. opaque 类型(some 协议)每个声明各自一个:
//      同协议、同函数体的两个函数, 编译器也当两个不同类型;
//      但运行时值的类型就是底层那个具体类型 (type(of:) 打出 青蛙)
// ============================================================================

protocol 会游泳 {}
protocol 只会游: AnyObject {}
struct 青蛙: 会游泳 {}
class 鱼: 会游泳, 只会游 {}
struct 大: 会游泳 {
    var a1 = 0, a2 = 0, a3 = 0, a4 = 0, a5 = 0, a6 = 0, a7 = 0, a8 = 0, a9 = 0, a10 = 0
    var a11 = 0, a12 = 0, a13 = 0, a14 = 0, a15 = 0, a16 = 0, a17 = 0, a18 = 0, a19 = 0, a20 = 0
}   // 20 个 Int = 160 字节
func 收<T: 会游泳>(_ x: T) {}
let 函数: (Int) -> Int = { $0 }

print("── 1. actor ──")
actor 计数器: 会游泳 { var n = 0 }
let 甲 = 计数器()
let 乙 = 甲
print("建得出:", 甲, "| 引用类型 (=== 同一份):", 甲 === 乙, "| 能符合协议 ✓")

print("\n── 2. 元组/函数 不能符合协议 ──")
收(青蛙())          // ✓
// 收((1, 2))       // ❌ error: type '(Int, Int)' cannot conform to '会游泳'
//                  //    note: only concrete types such as structs, enums and classes
//                  //          can conform to protocols
// 收(函数)         // ❌ error: type '(Int) -> Int' cannot conform to '会游泳'

print("\n── 3. any 协议 / Any: 大小定长 (装什么都不变) ──")
let 盒小: Any = 42
let 盒大: Any = 大()
print("Any:          装 Int", MemoryLayout.size(ofValue: 盒小),
      "| 装 160 字节", MemoryLayout.size(ofValue: 盒大))
let 泳小: any 会游泳 = 青蛙()
let 泳大: any 会游泳 = 大()
print("any 会游泳:    装青蛙", MemoryLayout.size(ofValue: 泳小),
      "| 装 160 字节", MemoryLayout.size(ofValue: 泳大))
let 限: any 只会游 = 鱼()
print("any 只会游:    限 class", MemoryLayout.size(ofValue: 限))
print("对照(随内容变): 元组(Int,Int)", MemoryLayout.size(ofValue: (1, 2)),
      "| 元组三个", MemoryLayout.size(ofValue: (1, 2, 3)),
      "| 函数", MemoryLayout.size(ofValue: 函数))

print("\n── 4. any 变量记着装的是什么类型 ──")
let 装青蛙: any 会游泳 = 青蛙()
let 装鱼: any 会游泳 = 鱼()
print("同一个声明类型 any 会游泳, 运行时:", type(of: 装青蛙), "/", type(of: 装鱼))
// let x = Any()   // ❌ error: 'Any' cannot be constructed because it has no accessible initializers

print("\n── 5. some 协议 (opaque): 每个声明各自一个 ──")
func 造甲()  -> some 会游泳 { 青蛙() }
func 造甲2() -> some 会游泳 { 青蛙() }   // 协议一样、函数体一字不差
func 同一个类型<T>(_ a: T, _ b: T) {}
// 同一个类型(造甲(), 造甲2())   // ❌ error: conflicting arguments to generic parameter 'T'
//                               //    ('some 会游泳' (result type of '造甲') vs. 'some 会游泳' (result type of '造甲2'))
print("造甲() 和 造甲2(): 编译期是两个类型 (报错原文见上, 注释掉了)")
print("运行时那个值: type(of: 造甲()) == 青蛙 →", type(of: 造甲()) == 青蛙.self)
