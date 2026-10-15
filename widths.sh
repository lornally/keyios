#!/usr/bin/env bash
#
# 在多个**屏宽**的 iPhone 上各截一张图 —— 用来确认底部条在不同宽度下
# "露几个、收几个进 ···"。
#
#   ./widths.sh        构建一次，然后在下面所有机型上依次截图
#
# 截图落在 shots/widths/，文件名就是机型名。
# 机器会自动创建（如果还没有），截完关机省内存 —— 但设备会留下，
# 你想在 Device Hub 里手动戳哪台都行。
#
set -euo pipefail
cd "$(dirname "$0")"

BUNDLE_ID=com.lornally.keyios
APP=".build/DerivedData/Build/Products/Debug-iphonesimulator/Keyios.app"
OUT="shots/widths"
RUNTIME_ID=$(xcrun simctl list runtimes | grep -o 'com\.apple\.CoreSimulator\.SimRuntime\.iOS-[0-9-]*' | head -1)

# 覆盖从最窄到最宽的整条谱：375 / 390 / 393 / 402 / 420 / 440 点
MODELS=(
  "iPhone SE (3rd generation)|com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation"
  "iPhone 16e|com.apple.CoreSimulator.SimDeviceType.iPhone-16e"
  "iPhone 17|com.apple.CoreSimulator.SimDeviceType.iPhone-17"
  "iPhone 18 Pro|com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro"
  "iPhone Air|com.apple.CoreSimulator.SimDeviceType.iPhone-Air"
  "iPhone 18 Pro Max|com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max"
)

# 只取**最新 iOS 版本**那一段的设备。
# 装了多代 runtime 后，列表里老系统的同名机型也在，直接 grep 会抓到老系统那台。
# （反转 -> 取到第一个分组头为止 -> 再反转回来）
newest_iphones() {
  xcrun simctl list devices available | tail -r | awk '{print} /^-- iOS/{exit}' | tail -r
}

# 先构建一次（后面的机型共用这个产物）
./build.sh --no-gen >/dev/null

mkdir -p "$OUT"

for ENTRY in "${MODELS[@]}"; do
  MODEL="${ENTRY%%|*}"          # | 左边是机型名
  DEVTYPE="${ENTRY##*|}"        # | 右边是机型 ID

  # 找一台这个型号的机器（UUID 就是那一长串十六进制）
  # 末尾的 `|| true` 是必须的：找不到时 grep 会返回 1，
  # 而脚本开了 `set -e`，会因此**静默退出**（踩过一次）。
  UDID=$(newest_iphones \
           | grep -F "$MODEL (" \
           | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
           | head -1 || true)

  # 没有就现造一台
  if [[ -z "$UDID" ]]; then
    echo "==> 创建模拟器: $MODEL"
    UDID=$(xcrun simctl create "$MODEL" "$DEVTYPE" "$RUNTIME_ID")
  fi

  echo "==> $MODEL"
  xcrun simctl bootstatus "$UDID" -b >/dev/null
  xcrun simctl install "$UDID" "$APP"
  xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$BUNDLE_ID" >/dev/null
  sleep 3
  xcrun simctl io "$UDID" screenshot "$OUT/$MODEL.png" >/dev/null 2>&1

  # 截一张就关机，别让 6 台模拟器一起开着吃内存
  xcrun simctl shutdown "$UDID"
done

echo
echo "==> 截图在 $OUT/"
ls "$OUT"
