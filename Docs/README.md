# mqtt-analyzer

<a href="https://apps.apple.com/de/app/mqttanalyzer/id1493015317?mt=8">![Download on AppStore](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2020-01-07&kind=iossoftware&bubble=apple_music)</a>

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=philipparndt_mqtt-analyzer&metric=alert_status)](https://sonarcloud.io/dashboard?id=philipparndt_mqtt-analyzer)

MQTTAnalyzer is an iOS App that allows to connect to your MQTT Broker and
subscribe to a topic. It is written in Swift using SwiftUI.

This App is open source, contributions are welcome.

Features:
- authentication with username/password or client certificates
- connect using MQTT or Websocket
- support for SSL/TLS
- support for self signed certificates
- create multiple broker settings
- messages are grouped by topic
- search/filter/focus-on for topics
- json highlighting and pretty printing
- publish messages
- publish json messages with a form
- sync settings using private iCloud database
- pause the connection
- connect to multiple brokers at once
- totally free and no ADs
- open source

# TestFlight

You can TestFlight the latest beta version using this link:
https://testflight.apple.com/join/dsvlFCPU

# Screenshots

## iOS
![Screenshot 1](screenshot-1.png)
![Screenshot 2](screenshot-2.png)
![Screenshot 3](screenshot-3.png)
![Screenshot 4](screenshot-4.png)
![Screenshot 5](screenshot-5.png)
![Screenshot 5](screenshot-6.png)

## macOS
![macOS Screenshot 1](macos-screenshot-1.png)
![macOS Screenshot 2](macos-screenshot-2.png)

# Examples

## AWS Iot

see [Create a certificate for AWS IoT](examples/aws/README)

## Traefik + Mosquitto + Let's Encrypt

see [Traefik + Mosquitto + Let's Encrypt](examples/traefik-tls/README)

# Developer notes

| Description           | Command           |
| --------------------- | ----------------- |
| Update pod repos      | `pod repo update` |
| Install / update pods | `pod install`     |
| Execute test cases    | `run-tests.sh`    |

## Realm on macOS
In case you get the error `Umbrella header 'Realm.h' not found` when creating an archive see:
https://github.com/realm/realm-swift/issues/3556#issuecomment-218990100

- Right click on `Pods/Realm/Headers/Realm` / Show file inspector
- Set target member to `Public`
- Do this for all header files (multi selection is possible)

