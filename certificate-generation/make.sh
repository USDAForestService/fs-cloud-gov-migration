export DIRECTORY_PREFIX="${1}"

mkdir "${DIRECTORY_PREFIX}"
mkdir "${DIRECTORY_PREFIX}"/certs
mkdir "${DIRECTORY_PREFIX}"/keys

export CURRENT_DIRECTORY=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
export ROOT_DIRECTORY="$(dirname "$CURRENT_DIRECTORY")"
echo "certificate-generation/${DIRECTORY_PREFIX}/*" >> "${ROOT_DIRECTORY}/.gitignore" # do not commit anything created


# Generate a x509 certificate that will be converted into a cert and a JWK for the 
# Login.gov on Open Forest Production Environment
openssl req -days 730 -newkey rsa:2048 -nodes -keyout "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-prod-login \
  -x509 -out certs/saml.crt.usda-forest-service-epermit-prod-login -config openssl-login-prod.conf

# Print out the login.gov dev public cert so can be sent to the identity-partners <partners@login.gov> to be registered 
# in the login.gov IDP
echo "LOGIN PROD CERT"
cat "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-prod-login

# Generate a x509 certificate that will be converted into a cert and a JWK for the 
# Login.gov on Open Forest Staging Environment
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-tree-login \
  -x509 -out "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-tree-login -config openssl-login-tree.conf

# Print out the login.gov dev public cert so that copy it to the https://dashboard.int.identitysandbox.gov/ 
echo "\nLOGIN DEV CERT"
cat "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-tree-login

# Produce a JWK to add to the VCAP Serices
# for Login.gov staging environment
echo "Downloading dependencies to generate jwk"
npm install
echo "Generating JWK"
node jwkmaker.js "${DIRECTORY_PREFIX}/keys/saml.key.enc.usda-forest-service-epermit-tree-login"

# Generate a x509 certificate that will be converted into a cert and a JWK for the USDA eAUTH SAML Partnership
# on Open Forest Production Environment
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-prod-eauth \
  -x509 -out "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-prod-eauth -config openssl-eauth-prod.conf

# Generate a x509 certificate that will be converted into a cert and a JWK for the USDA eAUTH SAML Partnership
# on Open Forest Staging Environment
openssl req -days 3650 -newkey rsa:2048 -nodes -keyout "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-dev-eauth \
  -x509 -out "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-dev-eauth -config openssl-eauth-dev.conf

# Print out the eAuth dev public cert so that copy it can be sent to USDA ICAM
# for the CERT environment
echo "\nEAUTH CERT DEV"
cat "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-dev-eauth

# Use the private key contents as a string in the VCAP services for the
# Open Forest Trees Staging enviornment eauth-service-provider private-key
echo "\nEAUTH KEY Dev"
cat "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-dev-eauth

echo "\nEAUTH CERT Prod"
cat "${DIRECTORY_PREFIX}"/certs/saml.crt.usda-forest-service-epermit-dev-eauth

# Print out the eAuth dev public cert so that copy it can be sent to USDA ICAM
echo "\nEAUTH KEY Prod"
cat "${DIRECTORY_PREFIX}"/keys/saml.key.enc.usda-forest-service-epermit-prod-eauth


# ## For pay.gov see pay.gov folder (because don't want to accidentally pollute openssl configs)
