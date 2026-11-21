#!/usr/bin/env bash
set -euo pipefail

# All images come from CoreSimulator's actual display, never a Flutter surface
# resized by a test. The pinned hinge helper changes simulator hardware pose.
capture_dir="${DUO_CAPTURE_DIR:-build/iphone-duo-simulator}"
mkdir -p "$capture_dir"

case "${1:-}" in
  prepare)
    xcodebuild -version > "$capture_dir/xcode-version.txt"
    xcrun simctl list --json > "$capture_dir/simulators.json"
    runtime_id="$(jq -er '.runtimes[] | select(.isAvailable and .version == "27.1") | select(any(.supportedDeviceTypes[]?; .name == "iPhone Duo")) | .identifier' "$capture_dir/simulators.json" | head -n 1)"
    device_type="$(jq -er '.devicetypes[] | select(.name == "iPhone Duo") | .identifier' "$capture_dir/simulators.json" | head -n 1)"
    device_id="$(xcrun simctl create Hacki-Duo-Screenshots "$device_type" "$runtime_id")"
    echo "HINGE_DEVICE=$device_id" >> "$GITHUB_ENV"
    export HINGE_DEVICE="$device_id"
    xcrun simctl boot "$device_id"
    xcrun simctl bootstatus "$device_id" -b
    xcrun simctl status_bar "$device_id" override --time '9:41' --batteryState charged --batteryLevel 100
    "$HINGE_BIN" close
    "$HINGE_BIN" orient portrait
    sleep 3
    "$HINGE_BIN" posture --json > "$capture_dir/initial-posture.json"
    ;;
  capture)
    name="${2:?Screenshot name required}"
    [[ "$name" =~ ^[a-z0-9-]+$ ]] || exit 2
    "$HINGE_BIN" posture --json > "$capture_dir/$name-posture.json"
    display_name="$(jq -er '.activeDisplay' "$capture_dir/$name-posture.json")"
    xcrun simctl io "$HINGE_DEVICE" screenshot --display="$display_name" "$capture_dir/$name.png"
    ;;
  pose)
    case "${2:-}" in
      open|close) "$HINGE_BIN" "$2" ;;
      rotate) "$HINGE_BIN" orient landscape-left ;;
      *) exit 2 ;;
    esac
    # Display activation follows the reported hinge angle asynchronously.
    sleep 3
    "$HINGE_BIN" posture --json > "$capture_dir/last-posture.json"
    ;;
  diagnose)
    xcrun simctl list --json > "$capture_dir/final-simulators.json" || true
    if [[ -n "${HINGE_DEVICE:-}" ]]; then
      xcrun simctl io "$HINGE_DEVICE" enumerate > "$capture_dir/display-ports.txt" 2>&1 || true
      "$HINGE_BIN" posture --json > "$capture_dir/final-posture.json" 2>&1 || true
      "$HINGE_BIN" screenshot "$capture_dir/final-diagnostic.png" || true
    fi
    ;;
  *) echo 'Usage: iphone_duo_capture.sh prepare|capture NAME|pose open|close|rotate|diagnose' >&2; exit 2 ;;
esac
