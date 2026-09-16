#!/usr/bin/env bash
# Kang Engineering Systems LLC, 2026, Copyright protection
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PACKAGE_ID="com.seankang.receipt"
TEST_FILE="integration_test/capture_save_upload_test.dart"

_tap_android_permission_allow() {
  adb -s "$DEVICE_ID" shell uiautomator dump /sdcard/camera2image_uidump.xml >/dev/null 2>&1 || return 0
  adb -s "$DEVICE_ID" pull /sdcard/camera2image_uidump.xml /tmp/camera2image_uidump.xml >/dev/null 2>&1 || return 0
  python3 - "$DEVICE_ID" <<'PY' || true
import re, subprocess, sys
device = sys.argv[1]
try:
    xml = open("/tmp/camera2image_uidump.xml", encoding="utf-8", errors="ignore").read()
except OSError:
    sys.exit(0)
labels = (
    "WHILE USING THE APP",
    "While using the app",
    "Allow",
    "ALLOW",
    "Only this time",
)
for label in labels:
    match = re.search(
        r'text="%s"[^>]*bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"' % re.escape(label),
        xml,
    )
    if not match:
        continue
    x1, y1, x2, y2 = map(int, match.groups())
    subprocess.run(
        ["adb", "-s", device, "shell", "input", "tap", str((x1 + x2) // 2), str((y1 + y2) // 2)],
        check=False,
    )
    break
PY
}

pick_device() {
  flutter devices --machine | python3 -c '
import json, sys

devices = json.load(sys.stdin)
skip_ids = {"chrome", "web-server", "edge", "safari"}
candidates = []
for device in devices:
    device_id = device.get("id") or ""
    platform = device.get("targetPlatform") or ""
    name = device.get("name") or device_id
    if device_id in skip_ids or platform.startswith("web"):
        continue
    emulator = bool(device.get("emulator"))
    is_android = "android" in platform
    is_ios = platform == "ios" or platform.startswith("ios")
    if is_android and emulator:
        rank = 0
    elif is_ios and emulator:
        rank = 1
    elif is_android:
        rank = 2
    elif is_ios:
        rank = 3
    else:
        rank = 4
    candidates.append((rank, device_id, name, platform))

if not candidates:
    sys.stderr.write("No running Flutter device found.\n")
    sys.exit(1)

candidates.sort()
device_id, name, platform = candidates[0][1], candidates[0][2], candidates[0][3]
sys.stderr.write("Using device: %s (%s, %s)\n" % (name, device_id, platform))
print("%s\t%s" % (device_id, platform))
'
}

DEVICE_SPEC="${1:-}"
if [[ -z "$DEVICE_SPEC" ]]; then
  DEVICE_LINE="$(pick_device)"
  DEVICE_ID="${DEVICE_LINE%%$'\t'*}"
  DEVICE_PLATFORM="${DEVICE_LINE#*$'\t'}"
else
  DEVICE_ID="$DEVICE_SPEC"
  DEVICE_PLATFORM="$(
    flutter devices --machine | python3 -c '
import json, sys
wanted = sys.argv[1]
for device in json.load(sys.stdin):
    if device.get("id") == wanted:
        print(device.get("targetPlatform") or "")
        break
' "$DEVICE_ID"
  )"
  echo "Using device: $DEVICE_ID ($DEVICE_PLATFORM)"
fi

grant_permissions() {
  if [[ "$DEVICE_PLATFORM" == android* ]]; then
    echo "Waiting to grant Android camera permissions to $PACKAGE_ID..."
    for _ in $(seq 1 300); do
      if adb -s "$DEVICE_ID" shell pm list packages | grep -q "$PACKAGE_ID"; then
        adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_ID" android.permission.CAMERA || true
        adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_ID" android.permission.RECORD_AUDIO || true
        echo "Granted Android camera permissions."
        # Keep re-granting in case the test APK is reinstalled.
        for _ in $(seq 1 120); do
          adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_ID" android.permission.CAMERA || true
          adb -s "$DEVICE_ID" shell pm grant "$PACKAGE_ID" android.permission.RECORD_AUDIO || true
          _tap_android_permission_allow || true
          sleep 1
        done
        return 0
      fi
      sleep 2
    done
    echo "Timed out waiting to grant Android permissions."
  elif [[ "$DEVICE_PLATFORM" == ios* ]]; then
    echo "Granting iOS simulator privacy permissions if applicable..."
    xcrun simctl privacy "$DEVICE_ID" grant camera "$PACKAGE_ID" 2>/dev/null || true
    xcrun simctl privacy "$DEVICE_ID" grant microphone "$PACKAGE_ID" 2>/dev/null || true
    xcrun simctl privacy "$DEVICE_ID" grant photos "$PACKAGE_ID" 2>/dev/null || true
  fi
}

grant_permissions &
GRANT_PID=$!

echo "Running QA integration test..."
set +e
flutter test "$TEST_FILE" -d "$DEVICE_ID"
TEST_STATUS=$?
set -e
kill "$GRANT_PID" 2>/dev/null || true
wait "$GRANT_PID" 2>/dev/null || true
exit "$TEST_STATUS"
