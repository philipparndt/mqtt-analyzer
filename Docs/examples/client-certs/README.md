# Connect with client certificates

This is an example on how to set-up client certificates.
To use this example you need to create self-singed certificates first.
Open the ./config/mosquitto folder in your terminal and run the following commands:

### Create root CA:
```sh
openssl genrsa -des3 -out ca.key 2048 # password
openssl req -new -x509 -days 1826 -key ca.key -out ca.crt
```

### Create broker certificate:
```sh
openssl genrsa -out broker.key 2048
openssl req -new -out broker.csr -key broker.key
openssl x509 -req -in broker.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out broker.crt -days 360
```

### Create client certificate:
```sh
openssl genrsa -out client.key 2048
openssl req -new -out client.csr -key client.key
openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 360
```

### Create P12 file:
```sh
openssl pkcs12 -export -in client.crt -inkey client.key -out client.p12
```

### Start the container:
```sh
docker compose up -d
``` 

### In MQTTAnalyzer:
Use the P12 file in MQTTAnalyzer to connect to the broker.
The settings are:

- Port: 8883
- SSL: `true`
- Allow untrusted: `true`
- Authentication: `Certificate`
- Client PKCS#12: `client.p12`
- Password: `password`