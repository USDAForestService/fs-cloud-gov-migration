#!/bin/bash

# Set Script Globals
INPUT_MIGRATION=${1:-true}
if [ "$INPUT_MIGRATION" == "true" ]; then
    FOR_MIGRATION=true
  else
    FOR_MIGRATION=false
fi
ORGNAME=usda-forest-service
OLDORG=gsa-acq-proto

# Import Env vars and module scripts
source ./bin/env.sh
source ./bin/middlelayer.sh
source ./bin/intake.sh
source ./bin/util.sh

# Download existing apps as sumbmodules
git submodule add https://github.com/18F/fs-intake-module.git fs-intake-module
git submodule add https://github.com/18F/fs-middlelayer-api.git fs-middlelayer-api
git submodule -q foreach git pull -q origin master #update sumbmodules

# Login to Cloud Foundry
cf login --sso -a api.fr.cloud.gov -o ${ORGNAME}

# CREATE ORG SPACES
cf create-space api-staging
cf create-space api-production
cf create-space public-staging
cf create-space public-production

#REBUILD MIDDLELAYER APPLICATION
cd fs-middlelayer-api || return

createMiddlelayerServices api-staging "${NRM_SUDS_URL_SERVICE_DEV_SUDS_API_URL}" "${NRM_SUDS_URL_SERVICE_password}" "${NRM_SUDS_URL_SERVICE_username}" "${AUTH_SERVICE_DEV_JWT_SECRET_KEY}"
createMiddlelayerServices api-production "${NRM_SUDS_URL_SERVICE_PROD_SUDS_API_URL}" "${NRM_SUDS_URL_SERVICE_password}" "${NRM_SUDS_URL_SERVICE_username}" "${AUTH_SERVICE_PROD_JWT_SECRET_KEY}"

if $FOR_MIGRATION; then
  #Free urls for middlelayer for both production and staging
  freeOldOrgUrl fs-api-staging fs-middlelayer-api-staging fs-middlelayer-api-staging
  freeOldOrgUrl fs-api-prod fs-middlelayer-api fs-middlelayer-api
fi

# Update cg-deploy orgs to Org name
if $FOR_MIGRATION; then
  # On old org-
  deployerChanges dev fs-api-prod api-production fs-api-staging api-staging
  deployerChanges master fs-api-prod api-production fs-api-staging api-staging
fi

# Push app on new org
cf t -o ${ORGNAME} -s api-production
git checkout master
cf push fs-middlelayer-api -f "./cg-deploy/manifests/manifest.yml"

cf t -s api-staging
git checkout dev
cf push fs-middlelayer-api-staging -f "./cg-deploy/manifests/manifest-staging.yml"
cd ..

# CREATE INTAKE SERVICES APP
cd fs-intake-module || return

createIntakeServices public-production "${MIDDLE_SERVICE_PROD_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_PROD_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_PROD_MIDDLELAYER_USERNAME}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_USERNAME}" "${LOGIN_SERVICE_PROVIDER_PROD_cert}" "${LOGIN_SERVICE_PROVIDER_PROD_issuer}"
createIntakeServices public-staging "${MIDDLE_SERVICE_DEV_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_USERNAME}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_USERNAME}" "${LOGIN_SERVICE_PROVIDER_DEV_cert}" "${LOGIN_SERVICE_PROVIDER_DEV_issuer}"

if $FOR_MIGRATION; then
  #Free urls for middlelayer for both production and staging
  freeOldIntakeOrgUrls

  #Update repos for deployment
  updateIntakeDeployment dev
  updateIntakeDeployment master
fi

# Push Intake apps on new org
brew install yarn
deployFrontEnd master production
deployFrontEnd dev staging
