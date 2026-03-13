# Kubernetes: Traefik SNI Routing to MQTT Broker

This example shows how to use Traefik in Kubernetes to route MQTT traffic on port 443 using SNI (Server Name Indication) with TLS passthrough.

## Architecture

```
Client <--TLS--> Traefik (K8s Ingress) <--TLS passthrough--> HiveMQ
         SNI: mqtt.local.rnd7.de                             (TLS termination)
```

- **Port 443** is shared for HTTPS and MQTTS
- **SNI** determines which backend receives traffic
- **TLS passthrough** means Traefik doesn't decrypt - the broker handles TLS

## Quick Start with k3d

### Prerequisites

- [k3d](https://k3d.io) - `brew install k3d`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh) - `brew install helm`
- Java keytool (comes with JDK)

### Setup

```bash
# Run the setup script
./setup.sh
```

This will:
1. Create k3d cluster with port 443 exposed
2. Create a k3d cluster with port 443 bound to `127.0.0.2`
3. Install Traefik via Helm
4. Generate TLS certificates
5. Deploy HiveMQ with TLS
6. Configure SNI-based routing

### Connect with MQTT Analyzer

| Setting | Value |
|---------|-------|
| Host | mqtt.local.rnd7.de |
| Port | 443 |
| TLS | On |
| Server CA | certs/ca.p12 (password: password) |

### Test with OpenSSL

```bash
openssl s_client -connect mqtt.local.rnd7.de:443 -servername mqtt.local.rnd7.de
```

### Test with Mosquitto

```bash
# Subscribe to all topics
mosquitto_sub -h mqtt.local.rnd7.de -p 443 --cafile certs/ca.crt -t "#" -v

# Publish a message
mosquitto_pub -h mqtt.local.rnd7.de -p 443 --cafile certs/ca.crt -t "test/hello" -m "Hello World"

# Debug mode (verbose output)
mosquitto_pub -h mqtt.local.rnd7.de -p 443 --cafile certs/ca.crt -t "test/hello" -m "Hello" -d
```

### Teardown

```bash
./teardown.sh
```

---

## Manual Setup (Existing Cluster)

### Prerequisites

- Kubernetes cluster with Traefik installed
- Traefik CRDs (IngressRouteTCP)
- TLS certificates for your MQTT domain

### Files

| File | Description |
|------|-------------|
| `hivemq.yaml` | HiveMQ deployment with TLS |
| `ingressroute.yaml` | Traefik IngressRouteTCP for SNI routing |
| `create-keystore.sh` | Generate certs and Java keystore |

### Setup

1. Create namespace:
```bash
kubectl create namespace mqtt
```

2. Generate certificates:
```bash
./create-keystore.sh mqtt.example.com
```

3. Create secret:
```bash
kubectl create secret generic hivemq-keystore \
  --from-file=keystore.jks \
  -n mqtt
```

4. Apply manifests:
```bash
kubectl apply -f hivemq.yaml
kubectl apply -f ingressroute.yaml
```

5. Connect using:
   - Host: `mqtt.example.com`
   - Port: `443`
   - TLS: On

## How SNI Routing Works

1. Client initiates TLS handshake to `mqtt.example.com:443`
2. SNI extension in ClientHello contains `mqtt.example.com`
3. Traefik reads SNI **before** TLS is established
4. Traefik routes to HiveMQ based on SNI match
5. HiveMQ completes TLS handshake with client

## Multiple Services on Port 443

You can route different hostnames to different backends:

| SNI Hostname | Backend |
|--------------|---------|
| `mqtt.example.com` | HiveMQ (MQTT) |
| `api.example.com` | API Server (HTTPS) |
| `app.example.com` | Web App (HTTPS) |

## ALPN Consideration

With TLS passthrough, ALPN negotiation happens between the client and HiveMQ directly. Since HiveMQ doesn't support ALPN, it will be ignored. This is fine for most use cases - ALPN is mainly needed for protocol multiplexing on the same port (like AWS IoT Core).

## Troubleshooting

Check Traefik logs:
```bash
kubectl logs -l app.kubernetes.io/name=traefik -n traefik
```

Check HiveMQ logs:
```bash
kubectl logs -l app=hivemq -n mqtt
```

Verify SNI routing:
```bash
openssl s_client -connect mqtt.example.com:443 -servername mqtt.example.com
```
