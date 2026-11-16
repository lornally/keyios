// ============================================================================
// 【列表里的一行】长什么样
// ============================================================================
// 目标长相（对齐 Keynote 稿）：
//
//     ( 今天   10:12 买菜   11:22 洗衣服 )
//       ↑绿色   ↑灰色 ↑白色
//
// 一行 = 缩减后的文件名 + 摘要（一级节点的原始文本，最多 3 条）。
// 数据里**没有**"时间"和"正文"两个字段 —— 摘要就是一整条字符串；
// 下面把开头的 "10:12" 拆出来上灰色，纯粹是显示层的临时做法
//（以后 dog 解析器会把前缀/正文/尾缀分好，那时这里就删掉）。
// ============================================================================

import SwiftUI

struct 单行V: View {

  /// 要画的这一篇
  let 日记: 日记

  // `var body: some View` 是 SwiftUI 每个视图的固定写法：
  // "我这个视图长什么样"。里面就是把它拼出来。
  var body: some View {

    // HStack = 横向排列（像 QHBoxLayout），spacing 是子元素间距
    HStack(spacing: 10) {

      // 文件名：缩减过的，主色绿，加粗
      Text(日记名f.缩写(日记.文件名))
        .foregroundStyle(Theme.accent)
        .fontWeight(.semibold)

      // 摘要（最多 3 条是加载时就截好的，这里照单画）
      ForEach(日记.摘要, id: \.self) { 摘要 in
        let 拆 = 拆时间(摘要)
        HStack(spacing: 4) {
          if let 时间 = 拆.时间 {
            Text(时间).foregroundStyle(Theme.secondaryText)  // 时间：灰
          }
          Text(拆.正文).foregroundStyle(Theme.primaryText)  // 正文：白
        }
      }
    }
    .font(.body)  // 系统正文 17pt, 且跟随"文字大小"设置
    .lineLimit(1)  // 一行放不下就截断（不折行）。想改成允许折两行就删掉这行。
    .frame(maxWidth: .infinity, alignment: .leading)

    // 内边距：上下 13、左右 14。数字直接改就能看效果。
    // 背景不在这里画 —— 一整个分块共用一张圆角底, 行与行之间只隔一根线
    // (见 p1列表.swift 的 分块/listContent)。
    .padding(.vertical, 13)
    .padding(.horizontal, 14)
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 摘要开头如果是 "10:12" 这种时间, 拆出来单独上灰色; 拆不出就整条当正文。
// 纯显示层的事 —— 数据里没这个字段。
// ────────────────────────────────────────────────────────────────────────────
private func 拆时间(_ 摘要: String) -> (时间: String?, 正文: String) {
  let 两截 = 摘要.split(separator: " ", maxSplits: 1)
  guard 两截.count == 2 else { return (nil, 摘要) }
  let 时分 = 两截[0].split(separator: ":")
  guard 时分.count == 2,
    let 时 = Int(时分[0]), let 分 = Int(时分[1]),
    时 < 24, 分 < 60
  else { return (nil, 摘要) }
  return (String(两截[0]), String(两截[1]))
}

// ────────────────────────────────────────────────────────────────────────────
// #Preview：不是 app 会跑的代码，只是给编辑器/预览工具"单独画这一屏"用。
// 这里挑了三行不同"时间远近"的（今天 / 前天 / 上月X日），方便一眼看出
// 文件名缩减后长短不一、摘要条数不一样时长什么样。
// （完整说明见 p1列表.swift 末尾）
// ────────────────────────────────────────────────────────────────────────────
#Preview {
  ZStack {
    Theme.background.ignoresSafeArea()
    VStack(spacing: 0) {
      单行V(日记: 日记表["26-10-16_日记"]!)
      Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 14)
      单行V(日记: 日记表["26-10-14_日记"]!)
      Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5).padding(.leading, 14)
      单行V(日记: 日记表["26-09-16_日记"]!)
    }
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Theme.rowBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .padding(.horizontal, 12)
  }
  .preferredColorScheme(.dark)
}
