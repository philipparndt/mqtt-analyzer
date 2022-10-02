#!/bin/bash
set -e

# Archive Location:
# ~/Library/Developer/Xcode/Archives

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
    fastlane ios publishSkipTests
popd
