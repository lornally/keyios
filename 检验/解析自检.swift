import Foundation

// 解析器的可运行自检 (没有测试框架, 就几条断言). 改了解析规则先跑它, 再看 app.
//
//   swiftc -swift-version 6 Keyios/d2脑图节点.swift Keyios/f3解析dog.swift \
//     检验/解析自检.swift -o /tmp/解析自检 && /tmp/解析自检

@main
struct 解析自检 {
  static func main() {
    let 样本 = """
      11:28 甲 done
        儿子
      ----- 昭 -----
      ●乙
        [[[
      块内第一行
      块内第二行
      ]]]
      ----- 父 -----
      参考.dog
      """

    let 结果 = dog解析.解析(样本)

    assert(结果.树.count == 2, "左右子树都该是顶层; 尾部区不该混进来")
    let 甲 = 结果.树[0]
    assert(甲.时间 == "11:28" && 甲.正文 == "甲" && 甲.图标 == "done")
    assert(甲.子.map(\.正文) == ["儿子"])
    let 乙 = 结果.树[1]
    assert(乙.正文 == "乙" && 结果.折叠.contains(乙.id), "● 节点要进折叠集")
    assert(乙.子.first?.正文 == "块内第一行\n块内第二行", "包装块内容要原样展开")

    print("解析自检通过")
  }
}
