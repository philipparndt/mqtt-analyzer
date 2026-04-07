#!/bin/bash
cd src
xcodebuild test \
-enableCodeCoverage YES \
-project MQTTAnalyzer.xcodeproj \
-scheme MQTTAnalyzer \
-destination 'platform=iOS Simulator,name=iPhone 11,OS=13.4'
