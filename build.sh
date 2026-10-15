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

# 5. 装 + 重启 (先 terminate, 否则可能拍到的还是上一版的旧界面)
APP="$DERIVED/Build/Products/Debug-iphonesimulator/$PROJECT.app"
xcrun simctl install "$UDID" "$APP"
xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null

# 6. 等它渲染完再截图
sleep 3
mkdir -p "$SHOTS"
SHOT="$SHOTS/latest.png"
xcrun simctl io "$UDID" screenshot "$SHOT" >/dev/null 2>&1
echo "==> 截图 $SHOT"
open "$SHOT"          # 直接弹出来看; 不想弹就注释掉这行
