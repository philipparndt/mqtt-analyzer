#!/bin/bash
set -e

DEVICES=(
    "iPhone 16 Pro Max"
    "iPhone 16 Pro"
    "iPad Pro 13-inch (M4)"
)

APPEARANCE="${APPEARANCE:-dark}"

echo "---- Setting appearance to ${APPEARANCE} ----"

for name in "${DEVICES[@]}"; do
    echo "Configuring: $name"

    xcrun simctl erase "$name" 2>/dev/null || true
    xcrun simctl boot "$name" 2>/dev/null || true

    if ! xcrun simctl ui "$name" appearance "$APPEARANCE"; then
        echo "Error setting appearance for $name"
    fi

    if ! xcrun simctl status_bar "$name" override \
        --time 9:41 \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100; then
        echo "Error applying status bar settings for $name"
    fi
done
