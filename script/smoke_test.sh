#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="ScreenShare"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
OUTPUT_IMAGE="$ROOT_DIR/dist/smoke-frame.png"
LOG_FILE="$ROOT_DIR/dist/smoke-test.log"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
rm -f "$OUTPUT_IMAGE" "$LOG_FILE"
"$ROOT_DIR/script/build_app_bundle.sh" \
  --configuration debug \
  --sign-mode none \
  --bundle-version 0.1.0 \
  --build-version 1 \
  --output-dir "$ROOT_DIR/dist" \
  --clean >/dev/null

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
