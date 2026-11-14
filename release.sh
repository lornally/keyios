#!/usr/bin/env bash
#
# 归档 → 导出 ipa → 上传 App Store Connect。不用打开 Xcode。
#
#   ./release.sh                 归档 + 导出 + 上传
#   ./release.sh --no-upload     只归档 + 导出, 不传 (先本地看能不能签过)
#
# 版本号:
#   VERSION=1.0.1 ./release.sh   商店版本号 (默认 1.0.0)
#   BUILD=123 ./release.sh       构建号 (默认当前时间 YYYYMMDDHHMM, 只会越来越大)
#
# 上传用的是 macOS 打包那套 ASC API key (和 macOS 版 Keydog 同一把)。
# 前提: App ID cn.isuyu.keyios 已在后台开好 iCloud + CloudDocuments,
#       并且 App Store Connect 里已经建了同名 app 记录。
set -euo pipefail
cd "$(dirname "$0")"

PROJECT=Keyios
SCHEME=Keyios
TEAM=S6C429H97P
KEY_ID=2286U5XBNK
ISSUER=0dba0a22-a772-40a8-98c9-46d2b083856c
API_KEY="$HOME/.private_keys/AuthKey_${KEY_ID}.p8"

VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-$(date +%Y%m%d%H%M)}"
OUT=.build/release
ARCHIVE="$OUT/Keyios.xcarchive"
EXPORT="$OUT/export"
IPA="$EXPORT/$PROJECT.ipa"

UPLOAD=1
if [[ "${1:-}" == "--no-upload" ]]; then UPLOAD=0; fi

# 1. 工程文件是产出的, 每次从 project.yml 重新生成
echo "==> xcodegen generate"
xcodegen generate >/dev/null

# 2. 归档 (Release, 真机架构)。-allowProvisioningUpdates 让 Xcode 自己拉/建分发 profile。
#    第一次跑会稍微久一点; 之后有缓存。
echo "==> archive  version=$VERSION build=$BUILD"
mkdir -p "$OUT"
xcodebuild archive \
  -project "$PROJECT.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -derivedDataPath .build/DerivedDataRelease \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM" \
  MARKETING_VERSION="$VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD" \
  2>&1 | tail -5

# 3. 导出 ipa。signingStyle=automatic 会用刚才归档时的签名身份。
echo "==> export ipa"
cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>teamID</key>
  <string>$TEAM</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>uploadSymbols</key>
  <true/>
  <key>manageAppVersionAndBuildNumber</key>
  <false/>
</dict>
</plist>
EOF
rm -rf "$EXPORT"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates \
  2>&1 | tail -5

if [[ $UPLOAD -eq 0 ]]; then
  echo "==> 只导出, 没上传: $IPA"
  exit 0
fi

# 4. 上传。altool 从 ~/.private_keys 找 .p8; 找不到时下面会直接报错。
echo "==> upload (altool)"
xcrun altool --upload-app \
  -f "$IPA" \
  -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER"

echo "==> 传完了。去 App Store Connect → TestFlight 等处理完 (通常几分钟)"
echo "    archive: $ARCHIVE"
echo "    ipa:     $IPA"
