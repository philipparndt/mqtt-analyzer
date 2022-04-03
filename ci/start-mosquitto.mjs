#!/usr/bin/env zx
try {
    await $`brew install mosquitto`
    await $`brew services start mosquitto`
}
catch (e) {
    console.log("Error stopping Mosquitto")
}