#!/bin/bash

# source ./util.sh  <- now sourced in migration


createIntakeServices()
{
  cf t -s ${1}
  cf create-service aws-rds shared-psql intake-db
  cf create-service s3 basic intake-s3
  cf create-service cloud-gov-service-account space-deployer intake-deployer
  cf create-service-key intake-deployer circle-ci-"${1}"
  cf service-key intake-deployer circle-ci-"${1}"

  if [ "${1}" == "platform-production" ]; then
    cf create-domain ${3} openforest.fs.usda.gov
    cf create-service custom-domain custom-domain my-domain \
    -c '{"domains": ["openforest.fs.usda.gov"]}'
  fi

  cf multi-cups-plugin "${2}"
}

freeOldIntakeOrgUrls()
{
  freeOldOrgUrl fs-intake-staging fs-intake-staging fs-intake-staging
  freeOldOrgUrl fs-intake-staging fs-intake-api-staging fs-intake-api-staging
  freeOldOrgUrl fs-intake-prod fs-intake-api fs-intake-api
  # unbind platform url manually because it has an associated route
}

updateIntakeDeployment(){
  updateDeployementOrgs ${1} "${OLDORG}" "${ORGNAME}" "update deployment to ${ORGNAME}"
  updateDeployementOrgs ${1} fs-intake-prod public-production "update prod space name"

  #Staging instance needs to be run manually because of recurrent use of the term
  git fetch
  git checkout "${1}"
  git pull origin "${1}"
  sed -i '' "s/= 'fs-intake-staging'/= 'platform-staging'/g" './cg-deploy/deploy.sh'
  sed -i '' 's/fs-intake-staging/platform-staging/g' './circle.yml'
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
  else
      MANIFEST_SUFFIX=""
  fi
  cf push open-forest-platform"${MANIFEST_SUFFIX}" -f "./cg-deploy/manifests/"${2}"/manifest-frontend"${MANIFEST_SUFFIX}".yml"
  cf push open-forest-platform-api"${MANIFEST_SUFFIX}" -f "./cg-deploy/manifests/"${2}"/manifest-api"${MANIFEST_SUFFIX}".yml"
  git reset --hard #because package lock will likely change
}
