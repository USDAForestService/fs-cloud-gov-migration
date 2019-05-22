# Generate a x509 certificate and private key

ROOT_DIR=./certificates
INT_ENV="${1}"
CONF="${ROOT_DIR}/conf/openssl-${INT_ENV}.conf"
PUBLIC="${ROOT_DIR}/certs/saml.crt.usda-forest-service-epermit-${INT_ENV}"
PRIVATE="${ROOT_DIR}/keys/saml.key.enc.usda-forest-service-epermit-${INT_ENV}"

printf "Generating\n  public key: %s\n  private key: %s\n  using configuration: %s\n" $PUBLIC $PRIVATE $CONF

openssl req \
  -days 3650 \
  -newkey rsa:2048 \
  -nodes \
  -keyout "${PRIVATE}" \
  -x509 \
  -out "${PUBLIC}" \
  -config "${CONF}"

echo "\nPublic CERT"
cat "${PUBLIC}"
echo "\nPrivate KEY"
cat "${PRIVATE}"