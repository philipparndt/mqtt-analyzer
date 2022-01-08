#!/bin/bash
xcrun simctl status_bar "iPhone 13 Pro" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPhone SE (2nd generation)" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPad Pro (11-inch) (3rd generation)" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100

xcrun simctl status_bar "iPad Air (4th generation)" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100