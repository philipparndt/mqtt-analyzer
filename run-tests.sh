#!/bin/bash
cd src
xcodebuild test \
-enableCodeCoverage YES \
-workspace MQTTAnalyzer.xcworkspace \
-scheme MQTTAnalyzer \
-destination 'platform=iOS Simulator,name=iPhone 11,OS=13.3'