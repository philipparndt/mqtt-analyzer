#!/usr/bin/env zx
try {
    await $`brew install apache-activemq@5.16.4`
    await $`/usr/local/opt/activemq/bin/activemq start`
}
catch (e) {
    console.log("Error stopping ActiveMQ")
}