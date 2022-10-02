# mqtt-analyzer

<a href="https://apps.apple.com/de/app/mqttanalyzer/id1493015317?mt=8">![Download on AppStore](https://linkmaker.itunes.apple.com/en-us/badge-lrg.svg?releaseDate=2020-01-07&kind=iossoftware&bubble=apple_music)</a>

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=philipparndt_mqtt-analyzer&metric=alert_status)](https://sonarcloud.io/dashboard?id=philipparndt_mqtt-analyzer)

MQTTAnalyzer is an iOS App that allows to connect to your MQTT Broker and
subscribe to a topic. It is written in Swift using SwiftUI.

This App is open source, contributions are welcome.

Features:
- Authentication with username/password or client certificates
- Connect using MQTT or Websocket
- Support for SSL/TLS
- Support for self-signed certificates
- MQTT 3.1.1 and MQTT 5.0
- Siri shortcuts for publish and receive messages
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


# TestFlight

You can TestFlight the latest beta version using this link:
https://testflight.apple.com/join/dsvlFCPU

# Screenshots

## iOS
<p float="left">
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-1.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-2.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-3.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-4.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-5.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-6.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-7.png" width="80"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/screenshot-8.png" width="80"/>
</p>

## macOS
<p float="left">
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/macos-screenshot-1.png" width="450"/>
<img src="https://github.com/philipparndt/mqtt-analyzer/raw/master/Docs/macos-screenshot-2.png" width="450"/>
</p>


# Examples

## AWS Iot

see [Create a certificate for AWS IoT](./examples/aws)

## Traefik + Mosquitto + Let's Encrypt

see [Traefik + Mosquitto + Let's Encrypt](./examples/traefik-tls)

# Developer notes

| Description           | Command           |
| --------------------- | ----------------- |
| Update pod repos      | `pod repo update` |
| Install / update pods | `pod install`     |
| Execute test cases    | `run-tests.sh`    |

## Thank you

<table>
  <tr>
  <td valign="center"><img src="https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.png" width="40"/> </td>
  <td valign="center">Thanks to JetBrains for sponsoring an all tools <a href="https://www.jetbrains.com/community/opensource/#support">Open Source License</a></td>
  </tr>
</table>
