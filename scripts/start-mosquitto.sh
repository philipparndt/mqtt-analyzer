#!/bin/bash
set -e

brew install mosquitto || true
cp ./mqtt-stub-service/config/mosquitto/config/mosquitto.conf /usr/local/etc/mosquitto/mosquitto.conf
brew services start mosquitto || echo "Error starting Mosquitto"
