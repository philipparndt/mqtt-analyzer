#!/bin/bash
cd "$(dirname)"
set -e

fastlane frameit download_frames

rm -rf ./screenshots
mkdir ./screenshots

array=( dark light )
for i in "${array[@]}"
do
    mkdir "./screenshots/$i"
    export APPEARANCE="$i"
    ./ci/prepare-screenshots.mjs

    pushd src
        fastlane screenshots

        pushd fastlane/screenshots
            fastlane frameit
            mv en-US/*_framed.png "../../../screenshots/$i"
        popd
    popd
done
