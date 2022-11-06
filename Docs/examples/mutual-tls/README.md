# mTLS example setup

This example shows how to set up a broker with mTLS authentication and how to connect to it with the MQTTAnalyzer.

## Create self-signed certificates

Execute: `./gen-certs.sh <your-hostname-or-ip>`

This will create a directory named `certs` with certificates and keys for:
- a self-signed root CA
- a server certificate signed by the root CA
- a client certificate signed by the root CA

The following files are relevant for an example setup:

| File         | Description                           |
| ------------ | ------------------------------------- |
| `ca.crt`     | `cafile` in mosquitto configuration   |
| `server.key` | `keyfile` in mosquitto configuration  |
| `server.crt` | `certfile` in mosquitto configuration |
| `client.p12` | Certificate file for MQTTAnalyzer     |

## Start the broker

Start the broker with `docker compose up`. The broker is listening on port `11883`.

## Configure MQTTAnalyzer

| Setting           | Value                  |
| ----------------- | ---------------------- |
| Hostname          | The specified hostname |
| Port              | `11883`                |
| Protocol          | `MQTT`                 |
| Version           | `3.1.1` or `5.0`       |
| TLS               | `ON`                   |
| Allow untrusted   | `ON`                   |
| Username/password | `ON`                   |
| Username          | `admin`                |
| Password          | `password`             |
| Certificate       | `ON`                   |
| Client PKCS#12    | The `client.p12` file  |
| Password          | `password`             |

## Limitations

You should not use this example in production. 

When you like to adapt this example to use in production, you should make changes to the `gen-certs.sh` script.
See comments in the script for details.

Remember always to keep your private keys in a safe place and choose strong passwords.

You should also use some trusted certificate authority instead of a self-signed root CA (like LetsEncrypt) 
and disable `Allow untrusted`. You could also add the generated `CA.crt` to the trusted certificates of your device.

