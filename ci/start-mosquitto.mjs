#!/usr/bin/env zx
try {
    await $`brew install mosquitto`
    await $`cp ./mqtt-stub-service/config/mosquitto/config/mosquitto.conf /usr/local/etc/mosquitto/mosquitto.conf`
    await $`brew services start mosquitto`
}
catch (e) {
    console.log("Error stopping Mosquitto")
}