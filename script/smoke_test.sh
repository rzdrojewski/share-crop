#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ScreenShare"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
MIN_SYSTEM_VERSION="14.0"
APP_BUNDLE_ID="com.remi.ScreenShare"
OUTPUT_IMAGE="$ROOT_DIR/dist/smoke-frame.png"
LOG_FILE="$ROOT_DIR/dist/smoke-test.log"

swift build >/dev/null
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
rm -f "$OUTPUT_IMAGE" "$LOG_FILE"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$APP_BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

cleanup() {
  launchctl unsetenv SCREENSHARE_SMOKE_TEST >/dev/null 2>&1 || true
  launchctl unsetenv SCREENSHARE_SMOKE_OUTPUT >/dev/null 2>&1 || true
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
}

trap cleanup EXIT

launchctl setenv SCREENSHARE_SMOKE_TEST 1
launchctl setenv SCREENSHARE_SMOKE_OUTPUT "$OUTPUT_IMAGE"
/usr/bin/open -n "$APP_BUNDLE"

for _ in {1..50}; do
  if [[ -f "$OUTPUT_IMAGE" ]]; then
    echo "Smoke test passed: $OUTPUT_IMAGE"
    exit 0
  fi
  sleep 0.2
done

echo "Smoke test failed. No frame written." >&2
tail -n 50 "$LOG_FILE" >&2 || true
exit 1
