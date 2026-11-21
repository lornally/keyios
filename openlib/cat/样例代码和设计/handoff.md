# cat 交接

## 这是什么

icon 关键词标准: `keywords.yaml` (关键词 → 图标名, key 唯一) + `macos.yaml` (图标名 → SVG).
各语言目录把它包装成该语言的原生包, 消费方用自己语言的工具链引入.

现有消费方: keyp 的 `code/s9svgtxt.py` (`from cat import 关键词, 图标`).

## 目录

- `keywords.yaml` / `macos.yaml` —— **唯一手改的数据源**. 值必须是字符串 (数字/布尔要加引号).
- `tools/build.py` —— YAML → `python/cat/_data.py` + `swift/Sources/Cat/Data.swift`. 需要 `pyyaml`.
- `python/` —— pip 包: `pyproject.toml` + `cat/__init__.py` (手写) + `cat/_data.py` (生成).
  用法: `pip install <本目录>/python`, 然后 `from cat import 关键词, 图标`.
- `swift/` —— SPM 包: `Package.swift` + `Sources/Cat/Cat.swift` (手写) + `Sources/Cat/Data.swift` (生成).
  用法: `.package(path: "<本目录>/swift")`, `import Cat`, 用 `keywords` / `icons` / `icon(for:)`.
- `样例代码和设计/` —— 设计稿/样例, 文件名故意中文, 不参与构建, 不要被任何包引用.
- `readme.md` —— 标准定义 (匹配规则/设计理由).

## 改数据后的唯一流程

```sh
python3 tools/build.py
```

校验 (任一失败直接报错): 重复 key、非字符串值、keywords 引用了 macos 里没有的图标、图标没被任何关键词引用.
然后提交: 两个 YAML + `python/cat/_data.py` + `swift/Sources/Cat/Data.swift`.

## 生成物要不要入库

**要**. `python/` 和 `swift/` 目录整体都要入库:
- 手写部分: pyproject / `__init__.py` / Package.swift / Cat.swift.
- 生成部分: `_data.py` / `Data.swift` —— 也必须提交, 因为 pip 和 SPM 直接消费仓库,
  不会替我们运行 `tools/build.py`. 不入库会导致 `pip install` / `swift build` 直接坏掉.

## 不要做

- 不要手改 `_data.py` / `Data.swift`.
- 不要改 Python 模块名 `cat` 或公开名 (`关键词` / `图标`), 也不要改 Swift 的 `keywords` / `icons` / `icon(for:)`;
  消费方已依赖. 要改先协调.
- 新增语言: 目录名纯拉丁; 手写该语言的包描述; 在 `tools/build.py` 加一个写出函数; 生成的数据文件同样入库.

## 现状

- 471 个关键词, 173 个图标 (含 81 个 `1.1`-`9.9` 小数徽标).
- 数据来自原 keyp 的 `s9svgtxt.py`.
- Swift 包已用 `swift build` 验证编译通过.

## 消费方联动

- keyp 的 pysidenv 是 editable 安装: 改 YAML 并重跑 `tools/build.py` 后立即生效.
- keyp 的打包 venv 是拷贝安装: cat 更新后需要重新 `pip install <本目录>/python`.
