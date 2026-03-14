#!/bin/bash

# This script creates a Java keystore for HiveMQ from PEM certificates
# Usage: ./create-keystore.sh <hostname>

if [ $# -eq 0 ]; then
    echo "Usage: ./create-keystore.sh <hostname>"
    echo "Example: ./create-keystore.sh mqtt.example.com"
    exit 1
fi

hostname=$1
password="changeit"
target="certs"

echo "Generating certificates for $hostname..."

rm -rf ./$target
mkdir -p $target

pushd $target > /dev/null

# Generate CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -subj "/CN=MQTT-CA" -out ca.crt

# Generate server certificate
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$hostname" -out server.csr

cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:$hostname, DNS:mtls.local.rnd7.de
EOF

openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out server.crt -days 720 -extfile server.ext

# Create PKCS12 keystore
openssl pkcs12 -export -in server.crt -inkey server.key \
    -out keystore.p12 -name server -passout pass:$password

# Convert to JKS (for HiveMQ)
keytool -importkeystore \
    -srckeystore keystore.p12 -srcstoretype PKCS12 -srcstorepass $password \
    -destkeystore keystore.jks -deststoretype JKS -deststorepass $password

# Create CA bundle for clients (PKCS12) - for Server CA validation
openssl pkcs12 -export -nokeys -in ca.crt -out ca.p12 -passout pass:password

# Generate client certificate for mTLS
echo "Generating client certificate for mTLS..."
openssl genrsa -out client.key 2048
openssl req -new -key client.key -subj "/CN=mqtt-client" -out client.csr

cat > client.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
    -out client.crt -days 720 -extfile client.ext

# Create client PKCS12 bundle (cert + key) for mTLS
openssl pkcs12 -export -in client.crt -inkey client.key \
    -out client.p12 -name client -passout pass:password

# Create truststore with CA for HiveMQ (to verify client certs)
keytool -importcert -alias ca -file ca.crt -keystore truststore.jks \
    -storepass $password -noprompt

# Cleanup
rm -f server.csr server.ext client.csr client.ext ca.srl keystore.p12

popd > /dev/null

echo ""
echo "Files created in $target/:"
echo ""
echo "Server certificates:"
echo "  - keystore.jks: Java keystore for HiveMQ (password: $password)"
echo "  - server.crt, server.key: Server PEM files"
echo ""
echo "CA certificates:"
echo "  - ca.crt: CA certificate for Server CA validation (PEM)"
echo "  - truststore.jks: CA truststore for HiveMQ - client cert validation (password: $password)"
echo ""
echo "Client certificates (mTLS):"
echo "  - client.crt, client.key: Client PEM files"
echo "  - client.p12: Client bundle for mTLS (password: password)"
echo ""
echo "Create Kubernetes secrets:"
echo "  kubectl create secret generic hivemq-keystore --from-file=$target/keystore.jks --from-file=$target/truststore.jks -n mqtt"
