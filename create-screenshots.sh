#!/bin/bash
cd "$(dirname)"
set -e
./ci/prepare-screenshots.mjs

pushd src
    fastlane screenshots
popd