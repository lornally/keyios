#!/usr/bin/env bash
#
# 构建 → 装进模拟器 → 启动 → 截图, 一条龙。
#
#   ./build.sh            完整一轮
#   ./build.sh --no-gen   跳过 xcodegen (工程没动过时省几秒)
#
# 截图落在 shots/, 不进版本库 (见 .gitignore)。
#
set -euo pipefail
cd "$(dirname "$0")"

PROJECT=Keyios
SCHEME=Keyios
BUNDLE_ID=com.lornally.keyios
DERIVED=.build/DerivedData          # DerivedData 放项目里, 不污染 ~/Library
SHOTS=shots

# 1. 由 project.yml 生成 .xcodeproj
#    工程文件是产物, 真源是 project.yml —— 所以 Xcode 改了它也不怕, 重跑一次就还原。
if [[ "${1:-}" != "--no-gen" ]]; then
  echo "==> xcodegen generate"
  xcodegen generate
fi

# 2. 挑一台 iPhone 模拟器 —— 只从**最新 iOS 版本**那一段里挑。
#
#    为什么要这么绕：装了多代 runtime 之后（比如同时有 iOS 26 和 27），
#    `simctl` 的列表是按版本**升序**排的，直接取"第一台 iPhone"
#    会拿到老系统那台 —— 踩过。
#
#    想指定机型：DEVICE="iPhone 17 Pro" ./build.sh
newest_iphones() {
  # 反转 -> 取到第一个 "-- iOS" 分组头为止（那就是最新版本那一段）-> 再反转回来
  xcrun simctl list devices available | tail -r | awk '{print} /^-- iOS/{exit}' | tail -r
}

if [[ -n "${DEVICE:-}" ]]; then
  UDID=$(newest_iphones | grep -F "$DEVICE (" \
           | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1 || true)
else
  UDID=$(newest_iphones | grep -E 'iPhone' \
           | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1 || true)
fi
if [[ -z "$UDID" ]]; then
  echo "没有可用的 iPhone 模拟器。先装 runtime:" >&2
  echo "  xcodebuild -downloadPlatform iOS" >&2
  exit 1
fi
echo "==> 模拟器 $UDID"

# 3. 启动它 (已经在跑就立刻返回)
xcrun simctl bootstatus "$UDID" -b >/dev/null

# 4. 构建。增量构建, 第一次慢后面快
echo "==> 构建"
xcodebuild -project "$PROJECT.xcodeproj" -scheme "$SCHEME" -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" \
  build 2>&1 | tail -5

# 5. 装 + 启动
#
#    关键概念：**模拟器之间不共享已安装的 app**。
#    每台模拟器有自己的文件系统、自己的一份安装 —— 装到哪台就得逐台装。
#
#    所以这里对**所有已开机的模拟器**都装一遍（先 terminate 再 launch，
#    否则可能拍到上一版的旧界面）。
#    用法：你在 Device Hub 里把想看的机型开机，跑一次 ./build.sh，
#    它们全都拿到最新版 —— 在 Device Hub 里切哪台都是最新的。
#
#    一台都没开机时，就开下面那台"主机器"（截图也用它）。
APP="$DERIVED/Build/Products/Debug-iphonesimulator/$PROJECT.app"
BOOTED=$(xcrun simctl list devices booted \
           | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)
if [[ -z "$BOOTED" ]]; then
  echo "==> 没有已开机的模拟器, 开机 $UDID"
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  BOOTED="$UDID"
fi

# 报个数 —— 开着的机器越多，这里越慢（每台都要装一遍）
echo "==> 已开机 $([[ -n "$BOOTED" ]] && echo "$BOOTED" | wc -l | tr -d ' ') 台, 逐台安装"

for D in $BOOTED; do
  xcrun simctl install "$D" "$APP"
  xcrun simctl terminate "$D" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$D" "$BUNDLE_ID" >/dev/null
  # 报机器名，不是一长串 UUID —— 看得出来装到哪台了
  NAME=$(xcrun simctl list devices | grep -F "$D" | head -1 | sed 's/^ *//; s/ (.*//')
  echo "    装好了 $NAME"
done

# 6. 等它渲染完再截图（固定拍主机器那台，方便前后对比）
sleep 3
mkdir -p "$SHOTS"
SHOT="$SHOTS/latest.png"
xcrun simctl io "$UDID" screenshot "$SHOT" >/dev/null 2>&1
echo "==> 截图 $SHOT"
open "$SHOT"          # 直接弹出来看; 不想弹就注释掉这行
