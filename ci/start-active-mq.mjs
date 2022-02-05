#!/usr/bin/env zx
try {
    await $`brew install apache-activemq`
    await $`/usr/local/opt/activemq/bin/activemq start`
}
catch (e) {
    console.log("Error stopping ActiveMQ")
}