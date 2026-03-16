#!/bin/bash

if [[ $# -eq 0 ]]; then
    echo "Expected hostname or ip address as first argument"
    echo "Usage: ./gen-certs.sh localhost"
    exit 1
fi

target="config/certs"
subj="/C=DE/ST=BW/O=rnd7"
hostname=$1

rm -rf ./$target
mkdir -p $target
pushd $target
    # Generate CA key and certificate
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -days 3650 -key ca.key -subj "$subj/CN=MQTT-CA" -out ca.crt

    # Generate CA as PKCS#12 bundle (for importing into apps)
    # Password: "password" (change for production)
    openssl pkcs12 -export -nokeys -in ca.crt -out ca.p12 -passout pass:password

    # Generate server key and certificate
    openssl genrsa -out server.key 2048
    openssl req -new -out server.csr -subj "$subj/CN=$hostname" -key server.key

    # Create config for SAN (Subject Alternative Name)
    cat > server.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $hostname
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
        -out server.crt -days 720 -extfile server.ext

    rm server.csr server.ext
popd

echo ""
echo "Certificates generated in $target/"
echo ""
echo "Files:"
echo "  - ca.p12: CA certificate bundle (password: password)"
echo "  - ca.crt: CA certificate (PEM)"
echo "  - server.crt/server.key: Server certificate and key"
echo ""
echo "To test with ALPN, configure your MQTT client with:"
echo "  - Host: $hostname"
echo "  - Port: 443"
echo "  - TLS: enabled"
echo "  - ALPN: mqtt"
echo "  - Server CA: ca.p12 (password: password)"
