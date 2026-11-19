# 1.1~9.9 小数编号徽标: 程序生成注入 svgdic (81 个结构相同的 SVG, 手写不如一行循环).
# 颜色按整数部分对齐 no1-no9; 数字走 <text> 元素 (no8 已有先例). 见 s9svgtxt.md.
_小数徽标色 = {
    "1": "#FFEAA7",
    "2": "#45B7D1",
    "3": "#FF6B6B",
    "4": "#BB8FCE",
    "5": "#FF9500",
    "6": "#96CEB4",
    "7": "#C7947A",
    "8": "#000000",
    "9": "#F7DC6F",
}


def _亮度(bg):
    """0-255 近似亮度. 浅底黑字: 除黑球外全用黑字 (对比度黑字全面优于白字)."""
    return (
        0.2126 * int(bg[1:3], 16)
        + 0.7152 * int(bg[3:5], 16)
        + 0.0722 * int(bg[5:7], 16)
    )


def _decimal_badge(text):
    """'2.1' → 彩色圆 + 数字文本 徽标 SVG."""
    bg = _小数徽标色[text[0]]
    fg = "#000000" if _亮度(bg) >= 64 else "#ffffff"
    stroke = (
        ' stroke="#ffffff" stroke-width="2"' if bg == "#000000" else ""
    )  # 黑球细白边
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 48 48">'
        f'<circle cx="24" cy="24" r="22" fill="{bg}"{stroke}/>'
        f'<text x="24" y="32" text-anchor="middle" font-size="22" fill="{fg}" '
        'font-family="Helvetica Neue, Arial, sans-serif" font-weight="300">'
        f"{text}</text></svg>"
    )


svgdic.update(
    {f" {i}.{j}": _decimal_badge(f"{i}.{j}") for i in "123456789" for j in "123456789"}
)
