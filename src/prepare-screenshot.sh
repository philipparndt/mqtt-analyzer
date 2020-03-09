#!/bin/bash
xcrun simctl status_bar "iPhone 11 Pro" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPhone 8" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPad Pro (11-inch)" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPad Air (3rd generation)" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100