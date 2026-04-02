# mqtt-analyzer

<a href="https://apps.apple.com/us/app/mqttanalyzer/id1493015317?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1578355200" alt="Download on the App Store" style="border-radius: 13px; width: 125px; height: 83px;"></a>

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=philipparndt_mqtt-analyzer&metric=alert_status)](https://sonarcloud.io/dashboard?id=philipparndt_mqtt-analyzer)

MQTTAnalyzer is an iOS and macOS App that allows you to connect to your MQTT Broker and
subscribe to topics. It is written in Swift using SwiftUI.

This App is open source, and contributions are welcome.

## Installation

### App Store (iOS and macOS)

MQTTAnalyzer is available on the [App Store](https://apps.apple.com/us/app/mqttanalyzer/id1493015317) for both iOS and macOS.
Note that App Store reviews can take some time, so the latest version may not always be available immediately.

### Homebrew (macOS)

For faster access to the latest version, you can install MQTTAnalyzer via Homebrew:

```bash
brew install philipparndt/mqtt-analyzer/mqtt-analyzer
```

To update to the latest version:

```bash
brew upgrade mqtt-analyzer
```

### Command Line Tool (macOS)

The macOS app includes a bundled CLI tool for subscribing to topics and publishing messages from the terminal.

**Install via the app:** Open MQTTAnalyzer, go to the app menu and select "Install Command Line Tool...". This creates a symlink at `/usr/local/bin/mqtt-analyzer`.

**Usage:**

```bash
# List configured brokers
mqtt-analyzer list

# Subscribe using the broker's configured subscriptions
mqtt-analyzer sub -b "My Broker"

# Subscribe to a specific topic
mqtt-analyzer sub -b "My Broker" "home/sensors/#"

# Subscribe with JSON output (includes topic, payload, qos, retain, timestamp)
mqtt-analyzer sub -b "My Broker" -j

# Subscribe with unwrapped JSON payloads (parses JSON payloads as nested objects)
mqtt-analyzer sub -b "My Broker" -u

# Override QoS for subscriptions
mqtt-analyzer sub -b "My Broker" --qos 2

# Publish a message
mqtt-analyzer pub -b "My Broker" "home/light" "on"

# Publish with QoS and retain
mqtt-analyzer pub -b "My Broker" "home/light" "on" --qos 1 --retain

# Publish from stdin
echo '{"state":"ON"}' | mqtt-analyzer pub -b "My Broker" "home/light" -

# Use a .mqttbroker file instead of a configured broker
mqtt-analyzer sub -f broker.mqttbroker "home/#"
```

### Features:
- Native macOS and iOS app
- Command line tool for subscribe and publish
- Authentication with username/password and/or client certificates
- Connect using MQTT or Websocket
- Support for SSL/TLS with ALPN
- Support for self-signed certificates
- Server CA certificate validation
- MQTT 3.1.1 and MQTT 5.0
- Siri shortcuts for publishing and receiving messages
- Create multiple broker settings
- Clone existing broker configurations
- Subscribe to multiple topics
- Topic tree view with hierarchical navigation
- Folder and flat view
- Messages are grouped by topic
- Read state tracking with unread indicators
- Statistics panel with topic and message counts
- Fulltext search for topics and payload
- JSON highlighting and pretty-printing
- ANSI escape code color rendering
- Time series charts for numeric payloads
- Publish messages with QoS and retain flag
- Publish JSON messages with a form
- Delete retained messages from broker
- Copy topics and payloads to clipboard
- Configurable message and topic limits
- Local and iCloud certificate storage
- Sync settings and certificates using iCloud
- Pause the connection
- Connect to multiple brokers at once
- Hex view for binary payloads with byte pairing
- Image viewer for binary payloads (PNG, JPEG, GIF, WebP, BMP, TIFF, HEIC) with pinch-to-zoom
- Large payload support with export functionality
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

## ALPN with HAProxy

see [ALPN with HAProxy](./examples/alpn)

## ALPN with Traefik

see [ALPN with Traefik](./examples/alpn-traefik)

## Kubernetes with Traefik SNI

see [Kubernetes with Traefik SNI](./examples/k8s-traefik-sni)

# Developer notes

See [DEVELOPMENT.md](./DEVELOPMENT.md)