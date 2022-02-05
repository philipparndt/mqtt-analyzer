#!/usr/bin/env zx

const devices = [
    "iPhone 13 Pro", 
    "iPhone SE (2nd generation)", 
    "iPad Pro (11-inch) (3rd generation)"
    //, "iPad Air (3rd generation)"
]
const papp = process.env["APPEARENCE"]
const appearance=papp ?? "dark" //  'dark' or 'light'

console.log(`---- Setting appearance to ${papp} ----`)

for (let name of devices) {
    try {
        await $`xcrun simctl erase ${name}`
    }
    catch (e) {
        // already booted?
    }

    try {
        await $`xcrun simctl boot ${name}`
    }
    catch (e) {
        // already booted?
    }

    try {
        await $`xcrun simctl ui ${name} appearance ${appearance}`
    }
    catch (e) {
        console.error(`Error setting dark mode of ${name}`, e)
    }

    try {
        await $`xcrun simctl status_bar ${name} override \
        --time 9:41 \
        --dataNetwork wifi \
        --wifiMode active \
        --wifiBars 3 \
        --cellularMode active \
        --cellularBars 4 \
        --batteryState charged \
        --batteryLevel 100`
    }
    catch (e) {
        console.error(`Error apply settings for ${name}`, e)
    }
}

