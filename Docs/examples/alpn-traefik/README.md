# ALPN (Application-Layer Protocol Negotiation) Example with Traefik

This example demonstrates how to set up an MQTT broker with TLS and ALPN support using Traefik + Mosquitto.

ALPN is a TLS extension that allows the client to indicate which application protocol it wants to use during the TLS handshake. This is commonly used with MQTT to specify the `mqtt` protocol, especially when connecting over port 443.

## Setup

1. Generate TLS certificates:

```bash
chmod +x gen-certs.sh
./gen-certs.sh localhost
```

2. Start the services:

```bash
docker compose up -d
```

3. The broker will be available at:
   - MQTT over TLS with ALPN: `localhost:443`
   - Traefik Dashboard: `http://localhost:8080`

## Connecting with MQTT Analyzer

Configure a new broker with these settings:

| Setting | Value |
|---------|-------|
| Hostname | localhost |
| Port | 443 |
| TLS | On |
| Server CA | ca.p12 (password: password) |
| ALPN | mqtt |

## Verifying ALPN

Test that ALPN is working:

```bash
openssl s_client -connect localhost:443 -alpn mqtt 2>&1 | grep -i alpn
```

Expected output:
```
ALPN protocol: mqtt
```

## How It Works

- **Traefik** handles TLS termination on port 443 with ALPN support configured via `dynamic.yml`
- **Mosquitto** runs plain MQTT on port 1883 (internal only)
- Traefik proxies the decrypted traffic to Mosquitto

## Common ALPN Values for MQTT

- `mqtt` - Standard MQTT protocol identifier
- `x-amzn-mqtt-ca` - AWS IoT Core ALPN identifier (for port 443 multiplexing)

## Troubleshooting

If connection fails:
1. Ensure certificates are generated in `config/certs/`
2. Check Traefik logs: `docker compose logs -f traefik`
3. Check Mosquitto logs: `docker compose logs -f mosquitto`
4. Verify the ALPN value matches (`mqtt` in this example)

## Note on ALPN Enforcement

Traefik advertises the `mqtt` ALPN protocol but does not enforce it by default. Clients without ALPN or with different ALPN values may still connect. For strict ALPN enforcement, consider using HAProxy (see the `alpn` example).
