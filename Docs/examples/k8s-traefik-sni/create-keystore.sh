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
subjectAltName = DNS:$hostname
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

# Create CA bundle for clients (PKCS12)
openssl pkcs12 -export -nokeys -in ca.crt -out ca.p12 -passout pass:password

# Cleanup
rm -f server.csr server.ext ca.srl keystore.p12

popd > /dev/null

echo ""
echo "Files created in $target/:"
echo "  - keystore.jks: Java keystore for HiveMQ (password: $password)"
echo "  - ca.p12: CA bundle for clients (password: password)"
echo "  - ca.crt, server.crt, server.key: PEM files"
echo ""
echo "Create Kubernetes secret:"
echo "  kubectl create secret generic hivemq-keystore --from-file=$target/keystore.jks -n mqtt"
