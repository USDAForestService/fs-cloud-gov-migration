ORGNAME=usda-forest-service

source ./bin/env.sh
source ./bin/util.sh
source ./bin/intake.sh

cf create-space public-login-test


deleteService public-login-test fs-intake-api-login-test login-service-provider
createIntakeServices public-login-test \
 "${MIDDLE_SERVICE_DEV_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_USERNAME}" \
 "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_USERNAME}" \
 "${LOGIN_SERVICE_PROVIDER_DEV_issuer}" "${LOGIN_SERVICE_PROVIDER_DEV_basic_auth_un}" "${LOGIN_SERVICE_PROVIDER_DEV_basic_auth_pass}" "${LOGIN_SERVICE_PROVIDER_DEV_jwk}" \
 "${EAUTH_DEV_ISSUER}" "${EAUTH_DEV_CERT}" "${EAUTH_DEV_PRIVATE_KEY}" "${EAUTH_DEV_ENTRYPOINT}"

cd fs-intake-module
 deployFrontEnd master login-test
