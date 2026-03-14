# Kubernetes: Traefik SNI Routing to MQTT Broker

This example shows how to use Traefik in Kubernetes to route MQTT traffic on port 443 using SNI (Server Name Indication) with TLS passthrough. It supports both standard TLS and mTLS (mutual TLS with client certificates).

## Architecture

```
Client <--TLS--> Traefik (K8s Ingress) <--TLS passthrough--> HiveMQ
         SNI: mqtt.local.rnd7.de                             (TLS termination)
```

- **Port 443** is shared for HTTPS and MQTTS
- **SNI** determines which backend receives traffic
- **TLS passthrough** means Traefik doesn't decrypt - the broker handles TLS

## Endpoints

| Hostname | Port | Description |
|----------|------|-------------|
| `mqtt.local.rnd7.de` | 443 | TLS only (no client cert required) |
| `mtls.local.rnd7.de` | 443 | mTLS (client cert required) |

## Quick Start with k3d

### Prerequisites

- [k3d](https://k3d.io) - `brew install k3d`
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [helm](https://helm.sh) - `brew install helm`
- Java keytool (comes with JDK)

### Setup

```bash
./setup.sh
```

This will:
1. Create k3d cluster with port 443 exposed
2. Install Traefik via Helm
3. Generate TLS and client certificates
4. Deploy HiveMQ with TLS and mTLS listeners
5. Configure SNI-based routing

### Teardown

```bash
./teardown.sh
```

---

## Security Configuration

This example includes authentication:

- **File-based RBAC authentication**: The HiveMQ File RBAC Extension is automatically downloaded and configured
- **Hashed passwords**: Passwords are hashed at deployment time
- **allow-all extension disabled**: The default permissive extension is disabled

The deployment uses init containers to:
1. Copy existing HiveMQ extensions
2. Download the [HiveMQ File RBAC Extension](https://github.com/hivemq/hivemq-file-rbac-extension)
3. Generate password hashes and create `credentials.xml`
4. Disable the `hivemq-allow-all-extension`

## Authentication

The broker requires authentication. Use these credentials:

| Username | Password |
|----------|----------|
| `mqtt-user` | `mqtt-password` |
| `admin` | `admin` |

> **Note:** Passwords are automatically hashed during deployment. To change passwords, edit the init container script in `hivemq.yaml`.

---

## TLS Connection (Username/Password Auth)

### Connect with MQTT Analyzer

| Setting | Value |
|---------|-------|
| Host | mqtt.local.rnd7.de |
| Port | 443 |
| TLS | On |
| Server CA | certs/ca.crt |
| Username | mqtt-user |
| Password | mqtt-password |

> **Note:** The Server CA field validates the broker's certificate against your custom CA. This is different from the Client P12 field which is used for mTLS client authentication.

### Test with Mosquitto

```bash
# Subscribe
mosquitto_sub -h mqtt.local.rnd7.de -p 443 --cafile certs/ca.crt -u mqtt-user -P mqtt-password -t "#" -v

# Publish
mosquitto_pub -h mqtt.local.rnd7.de -p 443 --cafile certs/ca.crt -u mqtt-user -P mqtt-password -t "test/hello" -m "Hello World"
```

### Test with OpenSSL

```bash
openssl s_client -connect mqtt.local.rnd7.de:443 -servername mqtt.local.rnd7.de
```

---

## mTLS Connection (Client Certificate + Credentials)

### Connect with MQTT Analyzer

| Setting | Value |
|---------|-------|
| Host | mtls.local.rnd7.de |
| Port | 443 |
| TLS | On |
| Server CA | certs/ca.crt |
| Certificate Authentication | On |
| Client PKCS#12 | certs/client.p12 (password: password) |
| Username | mqtt-user |
| Password | mqtt-password |

> **Note:** This example requires both client certificate AND username/password for defense in depth.

### Test with Mosquitto

```bash
# Subscribe
mosquitto_sub -h mtls.local.rnd7.de -p 443 \
  --cafile certs/ca.crt \
  --cert certs/client.crt \
  --key certs/client.key \
  -u mqtt-user -P mqtt-password \
  -t "#" -v

# Publish
mosquitto_pub -h mtls.local.rnd7.de -p 443 \
  --cafile certs/ca.crt \
  --cert certs/client.crt \
  --key certs/client.key \
  -u mqtt-user -P mqtt-password \
  -t "test/hello" -m "Hello mTLS"
```

### Test with OpenSSL

```bash
openssl s_client -connect mtls.local.rnd7.de:443 \
  -servername mtls.local.rnd7.de \
  -cert certs/client.crt \
  -key certs/client.key
```

---

## Generated Certificates

| File | Purpose | Password |
|------|---------|----------|
| `certs/ca.crt` | CA certificate (PEM) | - |
| `certs/ca.crt` | CA certificate for Server CA validation | - |
| `certs/server.crt` | Server certificate (PEM) | - |
| `certs/server.key` | Server private key (PEM) | - |
| `certs/keystore.jks` | Server keystore for HiveMQ | changeit |
| `certs/truststore.jks` | CA truststore for HiveMQ (client cert validation) | changeit |
| `certs/client.crt` | Client certificate (PEM) | - |
| `certs/client.key` | Client private key (PEM) | - |
| `certs/client.p12` | Client bundle for mTLS | password |

---

## How SNI Routing Works

1. Client initiates TLS handshake to `mqtt.local.rnd7.de:443`
2. SNI extension in ClientHello contains the hostname
3. Traefik reads SNI **before** TLS is established
4. Traefik routes to HiveMQ based on SNI match
5. HiveMQ completes TLS handshake with client

## Multiple Services on Port 443

You can route different hostnames to different backends:

| SNI Hostname | Backend |
|--------------|---------|
| `mqtt.local.rnd7.de` | HiveMQ port 8883 (TLS) |
| `mtls.local.rnd7.de` | HiveMQ port 8884 (mTLS) |
| `api.example.com` | API Server (HTTPS) |

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
openssl s_client -connect mqtt.local.rnd7.de:443 -servername mqtt.local.rnd7.de
```
