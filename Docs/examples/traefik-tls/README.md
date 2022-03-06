# Traefik with Mosquitto and TLS

This example shows a working set-up for Traefik + Mosquitto with
Let's Encrypt and username + password authentication.

You have to make some changes in the compose file according to
your domain and domain provider.

After the changes, this will work within your local network or on your server. 

## Preconditions

- You will need a public domain name from a hoster that Traefik supports. I used a domain from Ionos for my examples.
- When you like to host this in your local network, you will need a local DNS server that maps your domain name to a local server. I use Dnsmasq for this. Example: `address="/mqtt.example.com/192.168.3.50"`.
- You need a computer/server with docker and docker-compose.

## Make changes in the docker-compose.yml

### Your mail address

- `"--certificatesresolvers.myresolver.acme.email=mail@example.com"`

### Your provider settings

see [providers](https://doc.traefik.io/traefik/https/acme/#providers)

- `"--certificatesresolvers.myresolver.acme.dnsChallenge.provider=ionos"`
- `- IONOS_API_KEY=prefix.api_key`

### Your domain name
- ``- "traefik.http.routers.mqtt_websocket.rule=Host(`mqtt.example.com`)"``

### Username/password

This example uses `admin` / `password` as credentials for the login. 
You should change this when using it in production.

The password file is `./config/mosquitto/mosquitto.password`.

## Settings in MQTTAnalyzer

| Property        | Value              |
| --------------- | ------------------ |
| Hostname        | `mqtt.example.com` |
| Port            | `443`              |
| Protocol        | `Websocket`        |
| Basepath        | empty              |
| SSL             | `true`             |
| Allow untrusted | `false`            |
| Authentication  | `User/password`    |
| Username        | `admin`            |
| Password        | `password`         |

## Ionos specific information

Create an API key [here](https://developer.hosting.ionos.de/keys). 
You may have to enable the access with a support phone call first.

The syntax for the API key in `docker-compose.yml` is `${public-prefix}.${secret}`.
