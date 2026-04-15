#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="ScreenShare"
BUNDLE_ID="com.remi.ScreenShare"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_BINARY="$APP_MACOS/$APP_NAME"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

"$ROOT_DIR/script/build_app_bundle.sh" \
  --configuration debug \
  --sign-mode adhoc \
  --bundle-version 0.1.0 \
  --build-version 1 \
  --output-dir "$DIST_DIR" \
  --clean >/dev/null

open_app() {
  /usr/bin/open "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --smoke|smoke)
    "$ROOT_DIR/script/smoke_test.sh"
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--smoke]" >&2
    exit 2
    ;;
esac
