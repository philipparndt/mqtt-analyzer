#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVICES_FILE="$SCRIPT_DIR/../src/fastlane/devices.json"

# Export absolute path for fastlane
export DEVICES_JSON_PATH="$(cd "$SCRIPT_DIR/.." && pwd)/src/fastlane/devices.json"

# Parse devices from config/devices.json (single source of truth)
DEVICES=()
while IFS= read -r device; do
    DEVICES+=("$device")
done < <(jq -r '.[]' "$DEVICES_FILE")

APPEARANCE="${APPEARANCE:-dark}"

echo "---- Setting appearance to ${APPEARANCE} ----"

for name in "${DEVICES[@]}"; do
    echo "Configuring: $name"

    # Shutdown first if running, then boot fresh
    xcrun simctl shutdown "$name" 2>/dev/null || true
    xcrun simctl boot "$name" 2>/dev/null || true

    # Wait for simulator to be fully booted
    echo "  Waiting for simulator to boot..."
    xcrun simctl bootstatus "$name" -b 2>/dev/null || sleep 5

    # Set appearance
    echo "  Setting appearance to $APPEARANCE"
    if ! xcrun simctl ui "$name" appearance "$APPEARANCE"; then
        echo "  Error setting appearance for $name"
    fi

    # Set status bar
    if ! xcrun simctl status_bar "$name" override \
        --time 9:41 \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100; then
        echo "  Error applying status bar settings for $name"
    fi
done

# Small delay to ensure all settings are applied
sleep 2
