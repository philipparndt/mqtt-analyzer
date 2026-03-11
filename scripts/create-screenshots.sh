#!/bin/bash
cd "$(dirname "$0")/.."
set -e

FRAMES_DIR="$HOME/.fastlane/frameit/latest"
if [[ ! -d "$FRAMES_DIR" ]] || [[ "$1" == "--refresh-frames" ]]; then
    fastlane frameit download_frames
fi

rm -rf ./screenshots
mkdir ./screenshots

array=( dark light )
for i in "${array[@]}"
do
    mkdir "./screenshots/$i"
    export APPEARANCE="$i"
    ./scripts/prepare-screenshots.sh

    pushd src
        fastlane screenshots

        pushd fastlane/screenshots
            fastlane frameit
            mv en-US/*_framed.png "../../../screenshots/$i"
        popd
    popd
done
