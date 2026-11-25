#!/usr/bin/env bash
# Builds Dewy for the iOS Simulator and captures the README / App Store screenshots.
# Usage: bash scripts/screenshots.sh   (macOS with Xcode 16+)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=docs/screenshots
RAW=docs/raw
BUNDLE=com.dewyapp.Dewy
mkdir -p "$OUT" "$RAW"

echo "▸ $(xcodebuild -version | head -1)"

# Newest available iPhone "Pro" simulator (not Max) — falls back to any iPhone.
UDID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
data = json.load(sys.stdin)["devices"]
best = None
for runtime, devices in data.items():
    if "iOS" not in runtime:
        continue
    version = tuple(int(x) for x in runtime.split("iOS-")[-1].split("-") if x.isdigit())
    for device in devices:
        name = device["name"]
        if not name.startswith("iPhone"):
            continue
        score = (2 if ("Pro" in name and "Max" not in name) else 1, version, name)
        if best is None or score > best[0]:
            best = (score, device["udid"], name, runtime)
print(best[1])
print(best[2] + " / " + best[3], file=sys.stderr)
')
echo "▸ Simulator: $UDID"

xcodebuild -project Dewy.xcodeproj -scheme Dewy -configuration Debug \
  -sdk iphonesimulator -destination "id=$UDID" -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO -quiet build

APP=build/Build/Products/Debug-iphonesimulator/Dewy.app
test -d "$APP"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl ui "$UDID" appearance light || true
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active \
  --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
xcrun simctl install "$UDID" "$APP"

DATA=$(xcrun simctl get_app_container "$UDID" "$BUNDLE" data)
READY="$DATA/tmp/dewy-ready"

shoot() {
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
  rm -f "$READY"
  sleep 1
  xcrun simctl launch "$UDID" "$BUNDLE" "$@" >/dev/null
  # In demo mode the app writes a marker once its launch animations have settled.
  for _ in $(seq 1 60); do
    [ -f "$READY" ] && break
    sleep 1
  done
  [ -f "$READY" ] || echo "  … $name never signalled ready"
  sleep 2
  # CI simulators render on the CPU and can be slow to show the first frame:
  # a blank launch screen compresses to a tiny PNG, so retry until it's real.
  for _ in 1 2 3 4 5 6; do
    xcrun simctl io "$UDID" screenshot "$OUT/$name.png" >/dev/null 2>&1
    local size
    size=$(stat -f%z "$OUT/$name.png")
    if [ "$size" -gt 400000 ]; then break; fi
    echo "  … $name still launching ($size bytes)"
    sleep 6
  done
  echo "  📸 $name"
}

# Warm-up launch so the first real shot isn't caught mid-launch.
xcrun simctl launch "$UDID" "$BUNDLE" -screenshot today >/dev/null; sleep 20

shoot 01-today       -screenshot today
shoot 02-add-drink   -screenshot add
shoot 03-insights    -screenshot insights
shoot 04-garden      -screenshot garden
shoot 05-paywall     -screenshot paywall
shoot 06-settings    -screenshot settings
shoot 07-welcome     -screenshot onboarding -step 0
shoot 08-goal        -screenshot onboarding -step 5
shoot 09-peach       -screenshot today -theme peach
shoot 10-matcha      -screenshot garden -theme matcha -premium YES
shoot 11-lavender    -screenshot insights -theme lavender -premium YES
shoot 12-midnight    -screenshot today -theme midnight

# A short screen recording of Dewy reaching the daily goal (converted to a GIF later).
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null || true
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$RAW/celebrate.mp4" >/dev/null 2>&1 &
REC=$!
sleep 2
xcrun simctl launch "$UDID" "$BUNDLE" -screenshot celebrate >/dev/null
sleep 24
kill -INT "$REC"
wait "$REC" || true
echo "  🎬 celebrate.mp4"
ls -la "$OUT" "$RAW"
