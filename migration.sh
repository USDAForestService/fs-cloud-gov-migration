#!/bin/bash

INPUT_MIGRATION=${1:-true}
if [ "$INPUT_MIGRATION" == "true" ]; then
    FOR_MIGRATION=true
  else
    FOR_MIGRATION=false
fi

ORGNAME=usda-forest-service
OLDORG=gsa-acq-proto


# Import Env vars
source env.sh

# # Download existing apps as sumbmodules
git submodule add https://github.com/18F/fs-intake-module.git fs-intake-module
git submodule add https://github.com/18F/fs-middlelayer-api.git fs-middlelayer-api
#
cd fs-middlelayer-api || return
cf login -sso
cf t -o ${ORGNAME}

# Create spaces
cf create-space api-staging
cf create-space api-production
cf create-space public-staging
cf create-space public-production

#REBUILD MIDDLELAYER APPLICATION

createMiddlelayerServices()
{
  cf t -s "${1}"
  cf create-service aws-rds shared-psql fs-api-db
  cf create-service s3 basic fs-api-s3
  cf create-service cloud-gov-service-account space-deployer fs-api-deployer
  cf create-service-key fs-api-deployer circle-ci-"${1}"
  cf service-key fs-api-deployer circle-ci-"${1}"

  #User Provided services for credentials
  #Connection to SUDS
  NRM_SERVICES_JSON="{\"SUDS_API_URL\": \"${2}\", \"password\": \"${3}\", \"username\": \"${4}\"}"
  cf cups nrm-suds-url-service -p "${NRM_SERVICES_JSON}"

  #Authenication with consumer services
  AUTH_SERVICE_JSON="{\"JWT_SECRET_KEY\": \"${5}\"}"
  cf cups auth-service -p "${AUTH_SERVICE_JSON}"
}

createMiddlelayerServices api-staging "${NRM_SUDS_URL_SERVICE_PROD_SUDS_API_URL}" "${NRM_SUDS_URL_SERVICE_password}" "${NRM_SUDS_URL_SERVICE_username}" "${AUTH_SERVICE_DEV_JWT_SECRET_KEY}"
createMiddlelayerServices api-production "${NRM_SUDS_URL_SERVICE_PROD_SUDS_API_URL}" "${NRM_SUDS_URL_SERVICE_password}" "${NRM_SUDS_URL_SERVICE_username}" "${AUTH_SERVICE_PROD_JWT_SECRET_KEY}"

freeOldOrgUrl()
{
cf t -o "${OLDORG}" -s "${1}"
cf unmap-route "${2}" app.cloud.gov --hostname "${3}"
cf delete-route -f app.cloud.gov --hostname "${3}"
}

if $FOR_MIGRATION; then
  #Free urls for middlelayer for both production and staging
  freeOldOrgUrl fs-api-staging fs-middlelayer-api-staging fs-middlelayer-api-staging
  freeOldOrgUrl fs-api-prod fs-middlelayer-api fs-middlelayer-api
fi

Update cg-deploy orgs to Org name

updateDeployementOrgs()
{
  git fetch
  git checkout ${1}
  git push origin ${1}
  echo ${2}
  echo ${3}
  # for i; do
  #  echo $i
  REPLACER="s/"${2}"/"${3}"/g"
  echo $REPLACER
  sed -i '' $REPLACER './cg-deploy/deploy.sh'
  sed -i '' $REPLACER "./circle.yml"
  git add .
  git commit -m "${4}"
  git push origin "${1}"
}

deployerChanges()
{
  updateDeployementOrgs ${1} "${OLDORG}" "${ORGNAME}" "update deployment to ${ORGNAME}"
  updateDeployementOrgs ${1} ${2} ${3} "update prod space name"
  updateDeployementOrgs ${1} ${4} ${5} "update dev space name"
}

if $FOR_MIGRATION; then
  # On old org-
  deployerChanges dev fs-api-prod api-production fs-api-staging api-staging
  deployerChanges master fs-api-prod api-production fs-api-staging api-staging
fi

# Push app on new org
cf t -o ${ORGNAME} -s api-production
git checkout master # not sure if this makes sense
cf push fs-middlelayer-api -f "./cg-deploy/manifests/manifest.yml"

cf t -s api-staging
git checkout dev
cf push middlelayer-api-staging -f "./cg-deploy/manifests/manifest-staging.yml"

# CREATE INTAKE SERVICES APP
cd ..
cd fs-intake-module || return

createIntakeServices()
{
  cf t -s ${1}
  cf create-service aws-rds shared-psql intake-db
  cf create-service s3 basic intake-s3
  cf create-service cloud-gov-service-account space-deployer intake-deployer
  cf create-service-key intake-deployer circle-ci-"${1}"
  cf service-key intake-deployer circle-ci-"${1}"

  #Create user provided services
  #create service and provide credentials for connection to the middlelayer-service
  MIDDLELAYER_SERVICE_JSON="{\"MIDDLELAYER_BASE_URL\": \"${2}\", \"MIDDLELAYER_PASSWORD\": \"${3}\", \"MIDDLELAYER_USERNAME\": \"${4}\"}"
  cf cups middlelayer-service -p "${MIDDLELAYER_SERVICE_JSON}"

  # Create basic http auth for the api
  INTAKE_AUTH_SERVICE_JSON="{\"INTAKE_CLIENT_BASE_URL\": \"${5}\", \"INTAKE_PASSWORD\": \"${6}\", \"INTAKE_USERNAME\": \"${7}\"}"
  cf cups intake-auth-service -p "${INTAKE_AUTH_SERVICE_JSON}"

  #Todo eAuth and login services
}

createIntakeServices public-staging "${MIDDLE_SERVICE_PROD_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_PROD_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_PROD_MIDDLELAYER_USERNAME}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_PROD_INTAKE_USERNAME}"
createIntakeServices public-production "${MIDDLE_SERVICE_DEV_MIDDLELAYER_BASE_URL}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_PASSWORD}" "${MIDDLE_SERVICE_DEV_MIDDLELAYER_USERNAME}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_CLIENT_BASE_URL}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_PASSWORD}" "${INTAKE_CLIENT_SERVICE_DEV_INTAKE_USERNAME}"

if $FOR_MIGRATION; then
  # On old org-
  # Delete old routes
  freeOldOrgUrl fs-intake-staging fs-intake-staging fs-intake-staging
  freeOldOrgUrl fs-intake-staging fs-intake-api-staging fs-intake-api-staging
  freeOldOrgUrl fs-intake-prod fs-intake-api fs-intake-api
  freeOldOrgUrl fs-intake-prod forest-service-intake forest-service-epermit
fi

if $FOR_MIGRATION; then
  # Change spaces (FYI can't use the above  because the intake frontend app name is the same as the old space)
  updateDeployementOrgs dev "update deployment to ${ORGNAME}" "cg-deploy/*" ${OLDORG} ${ORGNAME}

  updateDeployementOrgs dev "update prod space name" "*" fs-intake-prod public-production
  updateDeployementOrgs master "update deployment to ${ORGNAME}" "cg-deploy/*" ${OLDORG} ${ORGNAME}
  updateDeployementOrgs master "update prod space name" "*" fs-intake-prod public-production

  #Staging instance needs to be run manually because of recurrent use of the term
  updateIntakeDevSpaceName()
  {
    git checkout "${1}"
    sed -i 's/fs-intake-staging/public-staging/g' "./circle.yml"
    sed - i "s/= 'fs-intake-staging'/= 'public-staging'/g" "./cg-deploy/deploy.sh"
    git add .
    git commit -m "update dev space name"
    git push origin "${1}"
  }
  updateIntakeDevSpaceName dev
  updateIntakeDevSpaceName master
fi

# Push apps on new org
brew install yarn
cd frontend || return
yarn
ng build --prod --env=prod;
cf t -o ${ORGNAME} -s public-production
git checkout master
cf push forest-service-epermit -f "./cg-deploy/manifests/production/manifest-frontend.yml"
cf push fs-intake-api -f "./cg-deploy/manifests/production/manifest-api.yml"
cd .. || return

cf t -s public-staging
git checkout dev
cd frontend || return
yarn
ng build --prod --env=prod;
cf push fs-intake-staging -f "./cg-deploy/manifests/staging/manifest-frontend-staging.yml"
cf push fs-intake-api-staging -f "./cg-deploy/manifests/staging/manifest-api-staging.yml"
