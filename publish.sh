#!/bin/bash
set -e

# Archive Location:
# ~/Library/Developer/Xcode/Archives
pushd ci
    zx realm-headers.mjs undo
popd 

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
### Run test cases (has to be done before Realm patch)
pushd src
    fastlane mac tests
popd

### Prepare Realm for macOS
pushd ci
    zx realm-headers.mjs apply
popd 

### Create macOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane mac publish
popd

### Undo prepare Realm for macOS
pushd ci
    zx realm-headers.mjs undo
popd 

## iOS ##################################
### Create iOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane ios publish
popd
