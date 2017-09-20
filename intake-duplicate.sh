#!/bin/bash

# Import Env vars and module scripts
source ./bin/env.sh
source ./bin/util.sh
source ./bin/intake.sh


cf login --sso -a api.fr.cloud.gov -o ${ORGNAME}
cf create-space trees-staging

createIntakeServices public-production \
"${MIDDLE_SERVICE_TREE_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_TREE_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_TREE_MIDDLELAYER_USERNAME}" \
 "${INTAKE_CLIENT_SERVICE_TREE_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_TREE_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_TREE_INTAKE_USERNAME}" \
 "${LOGIN_SERVICE_PROVIDER_TREE_issuer}" "${LOGIN_SERVICE_PROVIDER_TREE_basic_auth_un}" "${LOGIN_SERVICE_PROVIDER_TREE_basic_auth_pass}" "${LOGIN_SERVICE_PROVIDER_TREE_jwk}" \
"./json-envs/eauth-dev-tree.json" \
"./json-envs/google-relay-email.json"
