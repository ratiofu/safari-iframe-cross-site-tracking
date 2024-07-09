## if no certs directory exists, create it
[ ! -d "certs" ] && mkdir -p certs
echo "removing existing certificates files"
rm certs/*

# declare a list of strings representing the hosts for which to configure a certificate
# HOSTS=("test.parent-app.io" "app.embedded-app.io" "api.embedded-app.io")

delete_cert_by_name() {
  CERT_NAME=$1
  echo "attempting to remove '${CERT_NAME}' certificate"
  hashes=$(sudo security find-certificate -a -c "${CERT_NAME}" -Z | awk '/SHA-1/{print $NF}')
  if [ -z "$hashes" ]; then
      echo "certificate not found: ${CERT_NAME}"
  else
      echo "$hashes" | while read -r hash; do
          sudo security delete-certificate -Z "$hash" /Library/Keychains/System.keychain
          echo "deleted certificate: ${CERT_NAME}, SHA-1 hash: $hash"
      done
  fi
}

# path prefixes to your certificate file names
ROOT_CERT_PATH="./certs/root-ca"
PEAR_CERT_PATH="./certs/test.pear.com"
PEACH_CERT_PATH="./certs/embedded.peach.com"

echo "removing existing certificates from the System keychain"
echo "you may be prompted to enter your password, multiple times"

delete_cert_by_name "Test Root CA"

set -e

echo "generating private keys for the root"


openssl genrsa -out "${ROOT_CERT_PATH}.key" 2048
openssl genrsa -out "${PEAR_CERT_PATH}.key" 2048
openssl genrsa -out "${PEACH_CERT_PATH}.key" 2048

echo "generating root certificate for 'Test Root CA'"
openssl req -x509 -new -nodes -key "${ROOT_CERT_PATH}.key" -sha512 -days 1024 -out "${ROOT_CERT_PATH}.pem" -subj "/C=US/ST=Test/L=Test/O=Test/OU=Test/CN=Test Root CA"

echo "creating CSR for 'test.pear.com'"
openssl req -new -key "${PEAR_CERT_PATH}.key" -out "${PEAR_CERT_PATH}.csr" -config ./san-test.pear.com.config
echo "creating CSR for 'embedded.peach.com'"
openssl req -new -key "${PEACH_CERT_PATH}.key" -out "${PEACH_CERT_PATH}.csr" -config ./san-embedded.peach.com.config

echo "signing 'test.pear.com' CSR with the root certificate"
openssl x509 -req -in "${PEAR_CERT_PATH}.csr"  -CA "${ROOT_CERT_PATH}.pem" -CAkey "${ROOT_CERT_PATH}.key" \
 -CAcreateserial -out "${PEAR_CERT_PATH}.crt" -days 365 -sha512 -extensions v3_req -extfile ./san-test.pear.com.config
echo "signing 'embedded.peach.com' CSR with the root certificate"
openssl x509 -req -in "${PEACH_CERT_PATH}.csr" -CA "${ROOT_CERT_PATH}.pem" -CAkey "${ROOT_CERT_PATH}.key" \
 -CAcreateserial -out "${PEACH_CERT_PATH}.crt" -days 365 -sha512 -extensions v3_req -extfile ./san-embedded.peach.com.config

echo ""
echo "importing certificates to the System keychain"
echo ""
echo "installing Root CA certificate"
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${ROOT_CERT_PATH}.pem"

echo ""
echo "self-signed certificates for 'test.pear.com' and 'embedded.peach.com' created, imported, and trusted"
echo ""
echo "⚠️  make sure you're rebuilding and restarting the Nginx container"
