#!/bin/bash

# Publish example messages (retained) for screenshot testing
# Uses the mqtt-analyzer CLI (built from MQTTAnalyzerCLI target)
# These messages match the ExampleMessages.swift UI test class

set -e

BROKER="${1:-test.mqtt.rnd7.de}"
PORT="${2:-443}"
SSL="${3:-true}"

# Find mqtt-analyzer CLI (prefer Xcode DerivedData, then local builds, then installed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI=""
# Find Xcode DerivedData builds
XCODE_DD="$HOME/Library/Developer/Xcode/DerivedData"
if [[ -d "$XCODE_DD" ]]; then
    XCODE_CLI=$(find "$XCODE_DD" -name "mqtt-analyzer" -path "*/Build/Products/Debug/mqtt-analyzer" -not -path "*.app/*" 2>/dev/null | head -1)
    if [[ -x "$XCODE_CLI" ]]; then
        CLI="$XCODE_CLI"
    fi
fi
# Fallback to local builds and installed versions
if [[ -z "$CLI" ]]; then
    for candidate in \
        "$SCRIPT_DIR/../src/build/DerivedData-macOS/Build/Products/Debug/mqtt-analyzer" \
        "$SCRIPT_DIR/../src/build/DerivedData-CLI/Build/Products/Debug/mqtt-analyzer" \
        "/usr/local/bin/mqtt-analyzer" \
        "$(which mqtt-analyzer 2>/dev/null)"; do
        if [[ -x "$candidate" ]]; then
            CLI="$candidate"
            break
        fi
    done
fi

if [[ -z "$CLI" ]]; then
    echo "Error: mqtt-analyzer CLI not found."
    echo "Build it with: cd src && xcodebuild build -project MQTTAnalyzer.xcodeproj -scheme MQTTAnalyzerCLI -destination 'platform=macOS'"
    exit 1
fi

echo "Using CLI: $CLI"
echo "Publishing retained example messages to $BROKER:$PORT (ssl=$SSL)..."

# Create temporary brokerfile
BROKERFILE=$(mktemp /tmp/example-messages-XXXXXX)
mv "$BROKERFILE" "$BROKERFILE.mqttbroker"
BROKERFILE="$BROKERFILE.mqttbroker"
trap 'rm -f "$BROKERFILE"' EXIT

cat > "$BROKERFILE" << EOF
{
  "version": 1,
  "broker": {
    "alias": "Example Messages",
    "hostname": "$BROKER",
    "port": $PORT,
    "protocolMethod": "mqtt",
    "protocolVersion": "mqtt3",
    "basePath": "",
    "ssl": $SSL,
    "untrustedSSL": false,
    "authType": "none",
    "subscriptions": [{"topic": "#", "qos": 0}],
    "limitTopic": 0,
    "limitMessagesBatch": 500
  }
}
EOF

publish() {
    "$CLI" publish -f "$BROKERFILE" --qos 1 --retain "$1" "$2" 2>/dev/null
}

publish_file() {
    "$CLI" publish -f "$BROKERFILE" --qos 1 --retain --payload-file "$2" "$1" 2>/dev/null
}

# Dishwasher
publish "dishwasher/000123456789" '{"phase":"DRYING","phaseId":1799,"remainingDuration":"0:38","remainingDurationMinutes":38,"state":"RUNNING","timeCompleted":"10:20"}'

publish "dishwasher/000123456789/full" '{"ident":{"deviceIdentLabel":{"fabIndex":"64","fabNumber":"000123456789","matNumber":"10999999","swids":["1","2","3","4","5","6","7","8","9","10","11"],"techType":"G7560"},"deviceName":"","type":{"key_localized":"Devicetype","value_localized":"Dishwasher","value_raw":7},"xkmIdentLabel":{"releaseVersion":"03.59","techType":"EK037"}},"state":{"ProgramID":{"key_localized":"Program Id","value_localized":"","value_raw":6},"dryingStep":{"key_localized":"Drying level","value_localized":"","value_raw":null},"elapsedTime":[0,0],"light":2,"plateStep":[],"programPhase":{"key_localized":"Phase","value_localized":"Drying","value_raw":1799},"programType":{"key_localized":"Program type","value_localized":"Operation mode","value_raw":0},"remainingTime":[0,38],"remoteEnable":{"fullRemoteControl":true,"smartGrid":false},"signalDoor":false,"signalFailure":false,"signalInfo":false,"spinningSpeed":{"key_localized":"Spinning Speed","unit":"rpm","value_localized":null,"value_raw":null},"startTime":[0,0],"status":{"key_localized":"State","value_localized":"In use","value_raw":5},"targetTemperature":[{"unit":"Celsius","value_localized":null,"value_raw":-32768},{"unit":"Celsius","value_localized":null,"value_raw":-32768},{"unit":"Celsius","value_localized":null,"value_raw":-32768}],"temperature":[{"unit":"Celsius","value_localized":null,"value_raw":-32768},{"unit":"Celsius","value_localized":null,"value_raw":-32768},{"unit":"Celsius","value_localized":null,"value_raw":-32768}],"ventilationStep":{"key_localized":"Power Level","value_localized":"","value_raw":null}}}'

# Doorbell
publish "doorbell/front" '{"battery":85,"status":"idle","lastRing":"2026-03-21T09:15:00Z","linkquality":78}'

# Garage
publish "garage/door" '{"state":"closed","lastChanged":"2026-03-21T08:30:00Z","temperature":12.4}'

# Lights - kitchen
publish "light/kitchen/coffee-spot" '{"state":"ON","brightness":100,"color_temp":366}'
publish "light/kitchen/kitchen-1" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "light/kitchen/kitchen-2" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "light/kitchen/kitchen-3" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "light/kitchen/kitchen-4" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "light/kitchen/kitchen-5" '{"state":"OFF","brightness":100,"color_temp":366}'

# Lights - office
publish "light/office/left" '{"state":"ON","brightness":100,"color_temp":230}'
publish "light/office/center" '{"state":"ON","brightness":100,"color_temp":233}'
publish "light/office/right" '{"state":"ON","brightness":100,"color_temp":230}'

# Thermostat
publish "thermostat/living-room" '{"current_temperature":21.5,"target_temperature":22.0,"mode":"heat","state":"heating","battery":72}'

# Vacuum status
publish "vacuum/status" '{"state":"docked","battery":100,"cleanedArea":42.5,"cleanTime":35,"lastClean":"2026-03-21T07:00:00Z"}'

# Vacuum map (binary logo image)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_FILE="$SCRIPT_DIR/../src/MQTTAnalyzerUITests/TestLogo.png"

if [[ -f "$LOGO_FILE" ]]; then
    publish_file "vacuum/map" "$LOGO_FILE"
else
    echo "Warning: TestLogo.png not found at $LOGO_FILE, skipping vacuum/map"
fi

echo "Done! Published retained example messages to $BROKER:$PORT."
