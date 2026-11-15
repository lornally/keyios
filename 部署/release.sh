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
BUNDLE_ID=cn.isuyu.keyios
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
#
#    注意: Xcode 27.2 的 altool 每次新上传都会打印
#      CDUploaderStateInfoResumeFilePath ... The file doesn't exist
#    这是它在找"上次没传完的续传状态文件", 找不到是正常的, 不代表失败。
#    所以不看那行日志, 以退出码 + 下面用 App Store Connect API 查到的 build 为准。
echo "==> upload (altool)"
ALTOOL_LOG="$OUT/altool.log"
set +e
xcrun altool --upload-app \
  -f "$IPA" \
  -t ios \
  --apiKey "$KEY_ID" \
  --apiIssuer "$ISSUER" 2>&1 | tee "$ALTOOL_LOG"
ALTOOL_RC=${PIPESTATUS[0]}
set -e
echo "    altool exit=$ALTOOL_RC  (完整日志: $ALTOOL_LOG)"
echo "    (日志里的 CDUploaderStateInfoResumeFilePath 是噪音, 以 API 查询为准)"

# 5. 到 App Store Connect 查这个 build 到底到没到。最多等 3 分钟。
#    为什么还要查: altool 的日志/退出码在 Xcode 27.2 上不总是可靠, build 列表才是事实。
#    退出码: 0 = 查到了; 1 = 没查到/查询失败; 2 = 到了但处理失败(FAILED/INVALID)
echo "==> 查上传结果 (build $BUILD)"
set +e
ASC_KEY_ID="$KEY_ID" ASC_ISSUER="$ISSUER" ASC_KEY="$API_KEY" \
ASC_BUNDLE="$BUNDLE_ID" ASC_BUILD="$BUILD" python3 - <<'PY'
import os, sys, time, json, urllib.parse, urllib.request

try:
    import jwt
except Exception:
    print("  没装 PyJWT, 跳过 API 查询; 去 TestFlight 看 build %s" % os.environ.get("ASC_BUILD"))
    sys.exit(0)

key_id = os.environ["ASC_KEY_ID"]
issuer = os.environ["ASC_ISSUER"]
bundle = os.environ["ASC_BUNDLE"]
build = os.environ["ASC_BUILD"]
key = open(os.environ["ASC_KEY"]).read()
now = int(time.time())
token = jwt.encode(
    {"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
    key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"})

def get(path):
    req = urllib.request.Request(
        "https://api.appstoreconnect.apple.com" + path,
        headers={"Authorization": "Bearer " + token})
    return json.load(urllib.request.urlopen(req, timeout=30))

try:
    apps = get("/v1/apps?" + urllib.parse.urlencode(
        {"filter[bundleId]": bundle, "limit": "1"}))["data"]
    if not apps:
        print("  App Store Connect 里找不到 %s 的 app 记录" % bundle)
        sys.exit(1)
    app_id = apps[0]["id"]

    deadline = time.time() + 180
    last = []
    while True:
        try:
            last = get("/v1/builds?" + urllib.parse.urlencode(
                {"filter[app]": app_id, "limit": "20", "sort": "-uploadedDate"}))["data"]
        except Exception as e:
            print("  查 build 出错: %s" % e)
            last = []
        hit = [b for b in last if b["attributes"].get("version") == build]
        if hit:
            a = hit[0]["attributes"]
            state = a.get("processingState")
            if state != "PROCESSING" or time.time() >= deadline:
                print("  build %s: state=%s  uploaded=%s" % (
                    build, state, a.get("uploadedDate")))
                print("  https://appstoreconnect.apple.com/apps/%s/testflight/ios" % app_id)
                sys.exit(2 if state in ("FAILED", "INVALID") else 0)
        if time.time() >= deadline:
            break
        time.sleep(10)

    latest = last[0]["attributes"] if last else {}
    print("  3 分钟内没查到 build %s; 最新看到的是 %s (%s)" % (
        build, latest.get("version"), latest.get("processingState")))
    print("  去 TestFlight 刷新看看: https://appstoreconnect.apple.com/apps/%s/testflight/ios" % app_id)
    sys.exit(1)
except SystemExit:
    raise
except Exception as e:
    print("  查询失败: %s" % e)
    sys.exit(3)
PY
VERIFY_RC=$?
set -e

if [[ $VERIFY_RC -eq 2 ]]; then
  echo "==> build 到了, 但处理后状态是 FAILED/INVALID, 看上面的输出"
  exit 1
fi
if [[ $VERIFY_RC -ne 0 && $ALTOOL_RC -ne 0 ]]; then
  echo "==> 上传没成功 (altool exit=$ALTOOL_RC, 也没查到 build)"
  exit 1
fi
if [[ $VERIFY_RC -ne 0 ]]; then
  echo "==> altool 返回 $ALTOOL_RC, 但 3 分钟内没查到 build; 去 TestFlight 刷新确认"
fi
if [[ $VERIFY_RC -eq 0 && $ALTOOL_RC -ne 0 ]]; then
  echo "==> altool 报了非 0 退出码, 但 build 已经在 App Store Connect; 以 build 为准"
fi

echo "==> 完事。archive: $ARCHIVE"
echo "    ipa:     $IPA"
