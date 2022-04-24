#!/bin/bash
set -e

# Archive Location:
# ~/Library/Developer/Xcode/Archives
pushd ci
    zx realm-headers.mjs undo
popd 

### Install / build number
pushd src
    pod install
    fastlane ios incbuild # increment build number
popd

## macOS ################################ 
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
    fastlane ios publishSkipTests
popd
