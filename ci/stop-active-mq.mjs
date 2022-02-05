#!/usr/bin/env zx
try {
    await $`/usr/local/opt/activemq/bin/activemq stop`
}
catch (e) {
    console.log("Error stopping ActiveMQ")
}