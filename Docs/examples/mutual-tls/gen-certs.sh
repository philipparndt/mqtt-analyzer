if [ $# -eq 0 ]
  then
    echo "Expected hostname or ip address as first argument"
    exit 1
fi

target="certs"
subj="/C=DE/ST=BW/O=rnd7"
hostname=$1
username="User1"

rm -rf ./$target
mkdir $target
pushd $target
    # Add -des3 here and enter a password for production usage
    # openssl genrsa -des3 -out ca.key 2048
    openssl genrsa -out ca.key 2048
    openssl req -new -x509 -days 3650 -key ca.key -subj "$subj" -out ca.crt
    openssl genrsa -out server.key 2048
    openssl req -new -out server.csr -subj "$subj/CN=$hostname" -key server.key
    openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 720

    openssl genrsa -out client.key 2048
    openssl req -new -out client.csr -subj "$subj/CN=$username" -key client.key
    openssl x509 -req -in client.csr -CA ./ca.crt -CAkey ./ca.key -CAcreateserial -out client.crt -days 720

    # Remove -passout pass:password from the following line for production usage and chose your own strong password
    openssl pkcs12 -export -in client.crt  -inkey client.key -out client.p12  -passout pass:password
popd

cp certs/ca.crt config/ca.crt
cp certs/server.crt config/server.crt
cp certs/server.key config/server.key
