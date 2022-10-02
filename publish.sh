#!/bin/bash
set -e

# Archive Location:
# ~/Library/Developer/Xcode/Archives

### Test Env
pushd mqtt-stub-service
    docker compose up -d
popd


### Install / build number
pushd src
    pod install
    fastlane ios incbuild # increment build number
popd

## macOS ################################ 

### Create macOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane mac publish
popd

## iOS ##################################
### Create iOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane ios publish
popd
