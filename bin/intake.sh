#!/bin/bash

# source ./util.sh  <- now sourced in migration


createIntakeServices()
{
  cf t -s ${1}
  cf create-service aws-rds shared-psql intake-db
  cf create-service s3 basic intake-s3
  cf create-service s3 basic certs
  cf create-service cloud-gov-service-account space-deployer intake-deployer
  cf create-service-key intake-deployer circle-ci-"${1}"
  cf service-key intake-deployer circle-ci-"${1}"

  #Create user provided services
  #create service and provide credentials for connection to the middlelayer-service
  MIDDLELAYER_SERVICE_JSON="{\"MIDDLELAYER_BASE_URL\": \"${2}\", \"MIDDLELAYER_PASSWORD\": \"${3}\", \"MIDDLELAYER_USERNAME\": \"${4}\"}"
  cf cups middlelayer-service -p "${MIDDLELAYER_SERVICE_JSON}"

  # Create basic http auth for the api
  INTAKE_AUTH_SERVICE_JSON="{\"INTAKE_CLIENT_BASE_URL\": \"${5}\", \"INTAKE_PASSWORD\": \"${6}\", \"INTAKE_USERNAME\": \"${7}\"}"
  cf cups intake-client-service -p "${INTAKE_AUTH_SERVICE_JSON}"

  INTAKE_LOGIN_SERVICE_JSON="{\"jwk\": ${11}, \"issuer\": \"${8}\", \"IDP_USERNAME\": \"${9}\", \"IDP_PASSWORD\": \"${10}\"}"
  # echo "${INTAKE_LOGIN_SERVICE_JSON}"
  cf cups login-service-provider -p "${INTAKE_LOGIN_SERVICE_JSON}"

  INTAKE_EAUTH_SERVICE_JSON="{\"issuer\": \"${12}\", \"cert\": \"${13}\", \"privatekey\": \"${14}\", \"entrypoint\": \"${15}\"}"
  cf cups eauth-service-provider -p "${INTAKE_EAUTH_SERVICE_JSON}"
}

freeOldIntakeOrgUrls()
{
  freeOldOrgUrl fs-intake-staging fs-intake-staging fs-intake-staging
  freeOldOrgUrl fs-intake-staging fs-intake-api-staging fs-intake-api-staging
  freeOldOrgUrl fs-intake-prod fs-intake-api fs-intake-api
  freeOldOrgUrl fs-intake-prod forest-service-epermit forest-service-intake
}

updateIntakeDeployment(){
  updateDeployementOrgs ${1} "${OLDORG}" "${ORGNAME}" "update deployment to ${ORGNAME}"
  updateDeployementOrgs ${1} fs-intake-prod public-production "update prod space name"

  #Staging instance needs to be run manually because of recurrent use of the term
  git fetch
  git checkout "${1}"
  git pull origin "${1}"
  sed -i '' "s/= 'fs-intake-staging'/= 'public-staging'/g" './cg-deploy/deploy.sh'
  sed -i '' 's/fs-intake-staging/public-staging/g' './circle.yml'
  git add .
  git commit -m "update dev space name"
  git push origin "${1}"
}

deployFrontEnd(){
  cf t -o "${ORGNAME}" -s public-"${2}"
  git checkout "${1}"
  cd frontend || return
  yarn
  ng build --prod --env=prod;
  cd ..
  if [ "${2}" == "staging" ]; then
      MANIFEST_SUFFIX="-staging"
      APP="fs-intake-staging"
  elif [ "${2}" == "login-test" ]; then
    MANIFEST_SUFFIX="-login-test"
    APP="fs-intake-login-test"
  else
      MANIFEST_SUFFIX=""
      APP="forest-service-epermit"
  fi
  cf push "${APP}" -f "./cg-deploy/manifests/"${2}"/manifest-frontend"${MANIFEST_SUFFIX}".yml"
  # cf push fs-intake-api"${MANIFEST_SUFFIX}" -f "./cg-deploy/manifests/"${2}"/manifest-api"${MANIFEST_SUFFIX}".yml"
  git reset --hard #because yarn lock will likely change
}
