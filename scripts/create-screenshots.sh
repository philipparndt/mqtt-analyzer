#!/bin/bash
cd "$(dirname "$0")/.."
set -e

# Export absolute path for fastlane to find devices.json
export DEVICES_JSON_PATH="$(pwd)/src/fastlane/devices.json"

rm -rf ./screenshots
mkdir ./screenshots

for appearance in dark light; do
    mkdir "./screenshots/$appearance"
    export APPEARANCE="$appearance"
    ./scripts/prepare-screenshots.sh

    pushd src
        fastlane screenshots
        mv fastlane/screenshots/en-US/*.png "../screenshots/$appearance/"
    popd
done

echo ""
echo "Screenshots saved to ./screenshots/dark and ./screenshots/light"
echo ""
echo "Note: Device frames are not applied (frameit doesn't support iPhone 17)."
echo "For device frames, use an online tool like https://shotframe.app"
