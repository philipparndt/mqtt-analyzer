# mqtt-analyzer

<a href="https://apps.apple.com/de/app/mqttanalyzer/id1493015317?mt=8">![Download on AppStore](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2020-01-07&kind=iossoftware&bubble=apple_music)</a>

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=philipparndt_mqtt-analyzer&metric=alert_status)](https://sonarcloud.io/dashboard?id=philipparndt_mqtt-analyzer)

MQTTAnalyzer is an iOS App that allows you to connect to your MQTT Broker and
subscribe to a topic. It is written in Swift using SwiftUI.

This App is open source, and contributions are welcome.

### Features:
- Authentication with username/password and/or client certificates
- Connect using MQTT or Websocket
- Support for SSL/TLS
- Support for self-signed certificates
- MQTT 3.1.1 and MQTT 5.0
- Siri shortcuts for publishing and receiving messages
- Create multiple broker settings
- Subscribe to multiple topics
- Folder and flat view
- Messages are grouped by topic
- Fulltext search for topics and payload
- JSON highlighting and pretty-printing
- Publish messages
- Publish JSON messages with a form
- Sync settings using a private iCloud database
- Pause the connection
- Connect to multiple brokers at once
- Hex view for binary payload
- Predefined settings for AWS IoT
- Free and without any ADs
- Open source

# Project goals

The goal is to provide a great application for smart home development and give a good overview 
of the most recent and old payloads on an MQTT broker. 

- The application should work with any backend MQTT broker.
- No other backend services are necessary to execute this application.
- The latest version of macOS, iOS, and iPad OS are supported. 
Older versions are only supported by using an older version of the application. 
This is necessary to reduce the development overhead in fixing and testing older versions.

## No goals

Providing the best front end for controlling your smart home is not a goal. 
Every feature that will require extra backend services for push notifications is out of the scope of this application.

# TestFlight

You can TestFlight the latest beta version using this link:
https://testflight.apple.com/join/dsvlFCPU

# Screenshots

## iOS
<p float="left">
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-1.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-2.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-3.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-4.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-5.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-6.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-7.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/screenshot-8.png" width="80"/>
</p>

## macOS
<p float="left">
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/macos-screenshot-1.png" width="450"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/main/Docs/macos-screenshot-2.png" width="450"/>
</p>


# Examples

## AWS Iot

see [Create a certificate for AWS IoT](./examples/aws)

## Traefik + Mosquitto + Let's Encrypt

see [Traefik + Mosquitto + Let's Encrypt](./examples/traefik-tls)

## Mutual TLS (mTLS)

see [mutual-tls](./examples/mutual-tls)

# Developer notes

| Description | Command |
| --------------------- | ----------------- |
| Update pod repos | `pod repo update` |
| Install / update pods | `pod install` |
| Execute test cases | `run-tests.sh` |
