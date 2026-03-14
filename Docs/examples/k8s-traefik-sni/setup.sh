#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MQTT_HOST="mqtt.local.rnd7.de"
MTLS_HOST="mtls.local.rnd7.de"
MTLS_HOST_ALT="test.mqtt.rnd7.de"

echo "=== Setting up k3d MQTT cluster ==="

# Check prerequisites
command -v k3d >/dev/null 2>&1 || { echo "k3d is required. Install from https://k3d.io"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required."; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required."; exit 1; }

# Create cluster
echo ""
echo "=== Creating k3d cluster ==="
k3d cluster delete mqtt-cluster 2>/dev/null || true
k3d cluster create --config k3d-config.yaml

# Wait for cluster
echo ""
echo "=== Waiting for cluster to be ready ==="
kubectl wait --for=condition=Ready nodes --all --timeout=60s

# Install Traefik with Helm
echo ""
echo "=== Installing Traefik ==="
helm repo add traefik https://traefik.github.io/charts 2>/dev/null || true
helm repo update

helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set ports.websecure.port=443 \
  --set ports.websecure.exposedPort=443 \
  --set ports.traefik.expose.default=true \
  --set ingressRoute.dashboard.enabled=true \
  --set ingressRoute.dashboard.matchRule='Host(`traefik.localhost`)' \
  --set logs.general.level=INFO

# Wait for Traefik
echo ""
echo "=== Waiting for Traefik ==="
kubectl wait --for=condition=Available deployment/traefik -n traefik --timeout=120s

# Create MQTT namespace
echo ""
echo "=== Creating MQTT namespace ==="
kubectl create namespace mqtt 2>/dev/null || true

# Generate certificates
echo ""
echo "=== Generating certificates ==="
./create-keystore.sh "$MQTT_HOST" "$MTLS_HOST" "$MTLS_HOST_ALT"

# Create secrets
echo ""
echo "=== Creating Kubernetes secrets ==="
kubectl delete secret hivemq-keystore -n mqtt 2>/dev/null || true
kubectl create secret generic hivemq-keystore \
  --from-file=certs/keystore.jks \
  --from-file=certs/truststore.jks \
  -n mqtt

# Deploy HiveMQ
echo ""
echo "=== Deploying HiveMQ ==="
kubectl apply -f hivemq.yaml

# Wait for HiveMQ
echo ""
echo "=== Waiting for HiveMQ ==="
kubectl wait --for=condition=Available deployment/hivemq -n mqtt --timeout=120s

# Deploy IngressRoute
echo ""
echo "=== Deploying Traefik IngressRoute ==="
kubectl apply -f ingressroute-k3d.yaml

echo ""
echo "=== Setup complete! ==="
echo ""
echo "=== MQTT Analyzer Settings ==="
echo ""
echo "TLS Connection (username/password only):"
echo "  -- Server --"
echo "  Hostname:              $MQTT_HOST"
echo "  Port:                  443"
echo ""
echo "  -- TLS --"
echo "  Enable TLS:            On"
echo "  Allow untrusted:       Off"
echo "  Server CA:             certs/ca.crt"
echo ""
echo "  -- Authentication --"
echo "  Username/Password:     On"
echo "  Username:              mqtt-user"
echo "  Password:              mqtt-password"
echo "  Client Certificate:    Off"
echo ""
echo "mTLS Connection (client certificate + credentials):"
echo "  -- Server --"
echo "  Hostname:              $MTLS_HOST (or $MTLS_HOST_ALT)"
echo "  Port:                  443"
echo ""
echo "  -- TLS --"
echo "  Enable TLS:            On"
echo "  Allow untrusted:       Off"
echo "  Server CA:             certs/ca.crt"
echo ""
echo "  -- Authentication --"
echo "  Username/Password:     On"
echo "  Username:              mqtt-user"
echo "  Password:              mqtt-password"
echo "  Client Certificate:    On"
echo "  Client PKCS#12:        certs/client.p12"
echo "  Password:              password"
echo ""
echo "=== Test Commands ==="
echo ""
echo "Mosquitto (TLS):"
echo "  mosquitto_sub -h $MQTT_HOST -p 443 --cafile certs/ca.crt -u mqtt-user -P mqtt-password -i test-sub -t '#' -v"
echo "  mosquitto_pub -h $MQTT_HOST -p 443 --cafile certs/ca.crt -u mqtt-user -P mqtt-password -i test-pub -t 'test' -m 'Hello'"
echo ""
echo "Mosquitto (mTLS):"
echo "  mosquitto_sub -h $MTLS_HOST -p 443 --cafile certs/ca.crt --cert certs/client.crt --key certs/client.key -u mqtt-user -P mqtt-password -i test-sub -t '#' -v"
echo "  mosquitto_pub -h $MTLS_HOST -p 443 --cafile certs/ca.crt --cert certs/client.crt --key certs/client.key -u mqtt-user -P mqtt-password -i test-pub -t 'test' -m 'Hello'"
echo ""
echo "Traefik Dashboard: http://localhost:8080/dashboard/"
echo ""
