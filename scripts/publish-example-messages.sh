#!/bin/bash

# Publish example messages for screenshot testing
# Requires mosquitto_pub (brew install mosquitto)

BROKER="${1:-test.mqtt.rnd7.de}"
PORT="${2:-1883}"

echo "Publishing example messages to $BROKER:$PORT..."

publish() {
    mosquitto_pub -h "$BROKER" -p "$PORT" -t "$1" -m "$2" -q 2
}

# Home sensors
publish "home/sensors/water" '{"temperature":50.5}'
publish "home/sensors/air/in" '{"temperature":21.5625}'
publish "home/sensors/air/out" '{"temperature":23.1875}'
publish "home/sensors/bathroom/temperature" '{"battery":97,"humidity":37.17,"linkquality":31,"pressure":962,"temperature":22.58,"voltage":2995}'

# Contacts
publish "home/contacts/frontdoor" '{"battery":91,"contact":true,"linkquality":65,"voltage":2985}'

# Hue lights - kitchen
publish "hue/light/kitchen/coffee-spot" '{"state":"ON","brightness":100,"color_temp":366}'
publish "hue/light/kitchen/kitchen-1" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "hue/light/kitchen/kitchen-2" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "hue/light/kitchen/kitchen-3" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "hue/light/kitchen/kitchen-4" '{"state":"OFF","brightness":100,"color_temp":366}'
publish "hue/light/kitchen/kitchen-5" '{"state":"OFF","brightness":100,"color_temp":366}'

# Hue lights - office
publish "hue/light/office/left" '{"state":"ON","brightness":100,"color_temp":230}'
publish "hue/light/office/center" '{"state":"ON","brightness":100,"color_temp":233}'
publish "hue/light/office/right" '{"state":"ON","brightness":100,"color_temp":230}'

# Dishwasher
publish "home/dishwasher/000123456789" '{"phase":"DRYING","phaseId":1799,"remainingDuration":"0:38","remainingDurationMinutes":38,"state":"RUNNING","timeCompleted":"10:20"}'

publish "home/dishwasher/000123456789/full" '{
  "ident": {
    "deviceIdentLabel": {
      "fabIndex": "64",
      "fabNumber": "000123456789",
      "matNumber": "10999999",
      "swids": ["1","2","3","4","5","6","7","8","9","10","11"],
      "techType": "G7560"
    },
    "deviceName": "",
    "type": {
      "key_localized": "Devicetype",
      "value_localized": "Dishwasher",
      "value_raw": 7
    },
    "xkmIdentLabel": {
      "releaseVersion": "03.59",
      "techType": "EK037"
    }
  },
  "state": {
    "ProgramID": {"key_localized": "Program Id", "value_localized": "", "value_raw": 6},
    "dryingStep": {"key_localized": "Drying level", "value_localized": "", "value_raw": null},
    "elapsedTime": [0, 0],
    "light": 2,
    "plateStep": [],
    "programPhase": {"key_localized": "Phase", "value_localized": "Drying", "value_raw": 1799},
    "programType": {"key_localized": "Program type", "value_localized": "Operation mode", "value_raw": 0},
    "remainingTime": [0, 38],
    "remoteEnable": {"fullRemoteControl": true, "smartGrid": false},
    "signalDoor": false,
    "signalFailure": false,
    "signalInfo": false,
    "spinningSpeed": {"key_localized": "Spinning Speed", "unit": "rpm", "value_localized": null, "value_raw": null},
    "startTime": [0, 0],
    "status": {"key_localized": "State", "value_localized": "In use", "value_raw": 5},
    "targetTemperature": [
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768},
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768},
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768}
    ],
    "temperature": [
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768},
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768},
      {"unit": "Celsius", "value_localized": null, "value_raw": -32768}
    ],
    "ventilationStep": {"key_localized": "Power Level", "value_localized": "", "value_raw": null}
  }
}'

# Binary test messages
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGO_FILE="$SCRIPT_DIR/../src/MQTTAnalyzerUITests/TestLogo.png"

if [ -f "$LOGO_FILE" ]; then
    mosquitto_pub -h "$BROKER" -p "$PORT" -t "test/binary/logo" -f "$LOGO_FILE" -q 2
else
    echo "Warning: TestLogo.png not found at $LOGO_FILE"
fi

# Random binary data (256 bytes)
dd if=/dev/urandom bs=256 count=1 2>/dev/null | mosquitto_pub -h "$BROKER" -p "$PORT" -t "test/binary/raw" -s -q 2

echo "Done! Published example messages."
