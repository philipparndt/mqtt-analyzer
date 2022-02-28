#!/bin/bash
set -e

# Archive Location:
# ~/Library/Developer/Xcode/Archives

### Create macOS Archive
pushd src
    pod install
popd

## iOS ##################################
### Create iOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane ios incbuild # increment build number
    fastlane ios archive
popd

## macOS ################################ 
### Prepare Realm for macOS
pushd ci
    zx realm-headers.mjs undo
    zx realm-headers.mjs apply
popd 

### Create macOS Archive
pushd src
    rm -f MQTTAnalyzer.ipa MQTTAnalyzer.pkg
    fastlane mac archive
popd

### Undo prepare Realm for macOS
pushd ci
    zx realm-headers.mjs undo
popd 