#!/usr/bin/env bash
set -euo pipefail

APP_NAME="ScreenShare"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$DIST_DIR/release"
VERSION=""
ARTIFACT_VERSION=""
BUILD_VERSION=""

usage() {
  cat <<EOF
usage: $0 --version X.Y.Z [--artifact-version LABEL] [--build-version N]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --artifact-version)
      ARTIFACT_VERSION="$2"
      shift 2
      ;;
    --build-version)
      BUILD_VERSION="$2"
      shift 2
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

if [[ -z "$VERSION" ]]; then
  usage >&2
  exit 2
fi

if [[ -z "$ARTIFACT_VERSION" ]]; then
  ARTIFACT_VERSION="$VERSION"
fi

if [[ -z "$BUILD_VERSION" ]]; then
  BUILD_VERSION="$VERSION"
fi

STAGING_DIR="$RELEASE_DIR/staging/$ARTIFACT_VERSION"
APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$ARTIFACT_VERSION-unsigned.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
MOUNT_ROOT="$RELEASE_DIR/mount"
MOUNT_POINT="$MOUNT_ROOT/$ARTIFACT_VERSION"

rm -rf "$STAGING_DIR" "$MOUNT_POINT"
mkdir -p "$STAGING_DIR" "$RELEASE_DIR" "$MOUNT_ROOT"

"$ROOT_DIR/script/build_app_bundle.sh" \
  --configuration release \
  --sign-mode none \
  --bundle-version "$VERSION" \
  --build-version "$BUILD_VERSION" \
  --output-dir "$STAGING_DIR" \
  --clean >/dev/null

APP_BUNDLE="$STAGING_DIR/$APP_NAME.app"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

[[ -d "$APP_BUNDLE" ]]
[[ -x "$APP_BINARY" ]]
/usr/bin/plutil -lint "$INFO_PLIST" >/dev/null
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")" == "$VERSION" ]]
[[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST")" == "$BUILD_VERSION" ]]

rm -f "$DMG_PATH"
/usr/bin/hdiutil create \
  -quiet \
  -volname "$APP_NAME $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -format UDZO \
  -ov \
  "$DMG_PATH"

[[ -f "$DMG_PATH" ]]
/usr/bin/hdiutil imageinfo "$DMG_PATH" >/dev/null

mkdir -p "$MOUNT_POINT"
/usr/bin/hdiutil attach -quiet -nobrowse -readonly -mountpoint "$MOUNT_POINT" "$DMG_PATH" >/dev/null
trap '/usr/bin/hdiutil detach -quiet "$MOUNT_POINT" >/dev/null 2>&1 || true' EXIT

[[ -d "$MOUNT_POINT/$APP_NAME.app" ]]
[[ -x "$MOUNT_POINT/$APP_NAME.app/Contents/MacOS/$APP_NAME" ]]

/usr/bin/hdiutil detach -quiet "$MOUNT_POINT" >/dev/null
trap - EXIT
rm -rf "$MOUNT_POINT" "$STAGING_DIR"
rmdir "$MOUNT_ROOT" "$RELEASE_DIR/staging" >/dev/null 2>&1 || true

echo "$DMG_PATH"
