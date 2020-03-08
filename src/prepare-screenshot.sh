#!/bin/bash
xcrun simctl status_bar "iPhone 11" override \
--time 9:41 \
--dataNetwork wifi \
--wifiMode active \
--wifiBars 3 \
--cellularMode active \
--cellularBars 4 \
--batteryState charged \
--batteryLevel 100
