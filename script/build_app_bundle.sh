#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ScreenShare"
BUNDLE_ID="com.remi.ScreenShare"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/dist"
CONFIGURATION="debug"
SIGN_MODE="adhoc"
BUNDLE_VERSION="0.1.0"
BUILD_VERSION="1"
CLEAN_OUTPUT=0

usage() {
  cat <<EOF
usage: $0 [--output-dir PATH] [--configuration debug|release] [--sign-mode adhoc|none] [--bundle-version X.Y.Z] [--build-version N] [--clean]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --sign-mode)
      SIGN_MODE="$2"
      shift 2
      ;;
    --bundle-version)
      BUNDLE_VERSION="$2"
      shift 2
      ;;
    --build-version)
      BUILD_VERSION="$2"
      shift 2
      ;;
    --clean)
      CLEAN_OUTPUT=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$CONFIGURATION" in
  debug|release) ;;
  *)
    echo "unsupported configuration: $CONFIGURATION" >&2
    exit 2
    ;;
esac

case "$SIGN_MODE" in
  adhoc|none) ;;
  *)
    echo "unsupported sign mode: $SIGN_MODE" >&2
    exit 2
    ;;
esac

APP_BUNDLE="$OUTPUT_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
CODE_SIGNATURE_DIR="$APP_CONTENTS/_CodeSignature"

mkdir -p "$OUTPUT_DIR"

if [[ "$CLEAN_OUTPUT" -eq 1 ]]; then
  rm -rf "$APP_BUNDLE"
fi

swift build --configuration "$CONFIGURATION"
BUILD_BINARY="$(swift build --configuration "$CONFIGURATION" --show-bin-path)/$APP_NAME"

mkdir -p "$APP_MACOS"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$BUNDLE_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSCameraUsageDescription</key>
  <string>This app does not use the camera.</string>
  <key>NSScreenCaptureUsageDescription</key>
  <string>ScreenShare needs screen recording access to mirror a selected crop into a shareable window.</string>
</dict>
</plist>
PLIST

rm -rf "$CODE_SIGNATURE_DIR"
if [[ "$SIGN_MODE" == "adhoc" ]]; then
  /usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
fi

echo "$APP_BUNDLE"
