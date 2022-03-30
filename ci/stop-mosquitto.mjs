#!/usr/bin/env zx
try {
    await $`brew services stop mosquitto`
}
catch (e) {
    console.log("Error stopping ActiveMQ")
}