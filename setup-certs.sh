set -e

HOSTS=("test.parent-app.io" "app.embedded-app.io" "api.embedded-app.io")

## if no certs directory exists, create it
[ ! -d "certs" ] && mkdir -p certs
echo "removing existing certificates files"
rm certs/*

# root certificate section

ROOT_CERT_PATH_PREFIX="./certs/root-ca"

CERT_NAME="Test Root CA"
echo "attempting to remove '${CERT_NAME}' certificate(s)"
echo "you may be prompted to enter your password, multiple times"
hashes=$(sudo security find-certificate -a -c "${CERT_NAME}" -Z | awk '/SHA-1/{print $NF}')
if [ -z "$hashes" ]; then
    echo "certificate not found: ${CERT_NAME}"
else
    echo "$hashes" | while read -r hash; do
        sudo security delete-certificate -Z "$hash" /Library/Keychains/System.keychain
        echo "deleted certificate: ${CERT_NAME}, SHA-1 hash: $hash"
    done
fi
echo ""

echo "generate private key for the root certificate"
openssl genrsa -out "${ROOT_CERT_PATH_PREFIX}.key" 2048
echo ""

echo "generate root certificate for '${CERT_NAME}'"
openssl req -x509 -new -nodes -key "${ROOT_CERT_PATH_PREFIX}.key" \
  -sha512 -days 1024 -out "${ROOT_CERT_PATH_PREFIX}.pem" \
  -subj "/C=US/ST=Test/L=Test/O=Test/OU=Test/CN=Test Root CA"
echo ""

echo "installing Root CA certificate in the System keychain"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${ROOT_CERT_PATH_PREFIX}.pem"
echo ""

# host certificate section

generate_host_certificate() {
  HOST_NAME=$1
  echo ""
  echo "[$HOST_NAME] generating certificate for host"
  SAN_PATH="./certs/san-${HOST_NAME}.config"
  CERT_PATH_PREFIX="./certs/${HOST_NAME}"
  echo "[$HOST_NAME] generating SAN configuration file"
  cp ./san.config.template "${SAN_PATH}"
  sed -i '' "s/@hostname@/${HOST_NAME}/g" "${SAN_PATH}"
  echo "[$HOST_NAME] generating private key"
  openssl genrsa -out "${CERT_PATH_PREFIX}.key" 2048
  echo ""
  echo "[$HOST_NAME] creating CSR"
  openssl req -new -key "${CERT_PATH_PREFIX}.key" -out "${CERT_PATH_PREFIX}.csr" -config "${SAN_PATH}"
  echo ""
  echo "[$HOST_NAME] signing CSR with the root certificate"
  openssl x509 -req -in "${CERT_PATH_PREFIX}.csr" \
    -CA "${ROOT_CERT_PATH_PREFIX}.pem" \
    -CAkey "${ROOT_CERT_PATH_PREFIX}.key" \
    -CAcreateserial -out "${CERT_PATH_PREFIX}.crt" \
    -days 365 -sha512 -extensions v3_req -extfile "${SAN_PATH}"
  echo ""
  if ! grep -q "${HOST_NAME}" /etc/hosts; then
    echo "[$HOST_NAME] adding local host IP mapping to /etc/hosts"
    echo "127.0.0.1 ${HOST_NAME}" | sudo tee -a /etc/hosts
  fi
}

for HOST in "${HOSTS[@]}"; do
  generate_host_certificate "${HOST}"
done

echo ""
echo "done"
echo "⚠️  make sure you're rebuilding and restarting the Nginx container"
