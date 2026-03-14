# ALPN (Application-Layer Protocol Negotiation) Example

This example demonstrates how to set up an MQTT broker with TLS and ALPN support using HAProxy + Mosquitto.

ALPN is a TLS extension that allows the client to indicate which application protocol it wants to use during the TLS handshake. This is commonly used with MQTT to specify the `mqtt` protocol, especially when connecting over port 443.

## Architecture Options

This example supports two modes (configured in `haproxy.cfg`):

### Option 1: TLS Termination (default commented out)
```
Client <--TLS--> HAProxy <--plain--> Mosquitto
       (ALPN)    (terminates)
```

### Option 2: Re-encryption (default enabled)
```
Client <--TLS--> HAProxy <--TLS--> Mosquitto
       (ALPN)    (terminates)  (re-encrypts)
```

Both HAProxy and Mosquitto share the same certificates, providing end-to-end encryption while still allowing HAProxy to enforce ALPN.

## Setup

1. Generate TLS certificates:

```bash
./gen-certs.sh localhost
```

2. Start the services:

```bash
docker compose up -d
```

3. The broker will be available at:
   - MQTT over TLS with ALPN: `localhost:443`
   - HAProxy Stats: `http://localhost:8404/stats`

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

Test that wrong ALPN is rejected:

```bash
openssl s_client -connect localhost:443 -alpn wrong
```

This should fail to connect.

## Common ALPN Values for MQTT

- `mqtt` - Standard MQTT protocol identifier
- `x-amzn-mqtt-ca` - AWS IoT Core ALPN identifier (for port 443 multiplexing)

## Troubleshooting

If connection fails:
1. Ensure certificates are generated in `config/certs/`
2. Check HAProxy logs: `docker compose logs -f haproxy`
3. Check Mosquitto logs: `docker compose logs -f mosquitto`
4. Verify the ALPN value matches (`mqtt` in this example)
