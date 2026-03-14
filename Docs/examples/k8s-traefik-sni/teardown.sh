#!/bin/bash

echo "=== Deleting k3d MQTT cluster ==="
k3d cluster delete mqtt-cluster

echo ""
echo "=== Cleaning up generated files ==="
rm -rf certs

echo ""
echo "=== Done ==="
