ORGNAME=usda-forest-service

source ./bin/env.sh
source ./bin/util.sh
source ./bin/intake.sh

# cf create-space public-login-test


deleteService public-login-test fs-intake-api-login-test smtp-service
createIntakeServices public-login-test \
 "${MIDDLE_SERVICE_DEV_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_USERNAME}" \
 "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_USERNAME}" \
 "./json-envs/login-dev.json" \
 "./json-envs/eauth-dev.json" \
 "./json-envs/google-relay-email.json"

# cd fs-intake-module
#  deployFrontEnd master login-test
