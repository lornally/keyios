#!/usr/bin/env bash
#
# 真机: 构建 -> 安装 -> 启动。不用等 TestFlight (上传+处理), 插上 iPhone 就能测。
#
#   ./device.sh             Release 构建, 和 TestFlight 同一份配置
#   ./device.sh --debug     Debug 构建
#   DEVICE=<UDID> ./device.sh   多台真机时指定用哪台
#
# 前提:
#   * iPhone 用数据线连着 Mac, 已解锁, 已在"访达/Xcode"里点过"信任"
#   * iPhone 已开 设置 -> 隐私与安全性 -> 开发者模式 (开的时候会要求重启一次)
#   * 自动签名会用 project.yml 里的 DEVELOPMENT_TEAM 去拉开发 profile
#
# 和 build.sh 的分工:
#   build.sh  = 模拟器 (读 Mac 上真实 iCloud 目录, 能测界面, 测不到 iCloud 容器)
#   device.sh = 真机   (走真的 iCloud 容器, "第一次打开慢"只有这里能复现)
set -euo pipefail
cd "$(dirname "$0")"

PROJECT=Keyios
SCHEME=Keyios
BUNDLE_ID=cn.isuyu.keyios

CONFIG=Release
if [[ "${1:-}" == "--debug" ]]; then CONFIG=Debug; fi

echo "==> xcodegen generate"
xcodegen generate >/dev/null

# 找真机: devicectl 列表里带 simulated 的是模拟器; 真机的 UDID 形如
# 00008101-0005150A213A001E (8-16 位十六进制)
if [[ -z "${DEVICE:-}" ]]; then
  DEVICE=$(xcrun devicectl list devices 2>/dev/null \
    | grep -v simulated \
    | grep -oiE '[0-9a-f]{8}-[0-9a-f]{16}' | head -1 || true)
fi
if [[ -z "${DEVICE:-}" ]]; then
  echo "没找到真机。插上 iPhone, 解锁, 点\"信任\"再来。" >&2
  exit 1
fi
echo "==> 真机 $DEVICE"

echo "==> 构建 ($CONFIG)"
xcodebuild -project "$PROJECT.xcodeproj" -scheme "$SCHEME" -configuration "$CONFIG" \
  -destination "id=$DEVICE" -derivedDataPath .build/device \
  -allowProvisioningUpdates build 2>&1 | tail -5

APP=".build/device/Build/Products/$CONFIG-iphoneos/$PROJECT.app"
if [[ ! -d "$APP" ]]; then
  echo "没找到 $APP" >&2
  exit 1
fi

echo "==> 安装"
xcrun devicectl device install app --device "$DEVICE" "$APP"

echo "==> 启动"
xcrun devicectl device process launch --terminate-existing --device "$DEVICE" "$BUNDLE_ID"
