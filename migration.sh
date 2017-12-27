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
NOT_REBUILD_SERVICE=false

# Import Env vars and module scripts
source ./bin/env.sh
source ./bin/util.sh
source ./bin/middlelayer.sh
source ./bin/intake.sh

if $NOT_REBUILD_SERVICE; then
  # Download existing apps as sumbmodules
  git submodule add https://github.com/18F/fs-permit-platform.git fs-permit-platform
  git submodule add https://github.com/18F/fs-middlelayer-api.git fs-middlelayer-api
  git submodule -q foreach git pull -q origin master #update sumbmodules

  # Login to Cloud Foundry
  cf login --sso -a api.fr.cloud.gov -o ${ORGNAME}

  # CREATE ORG SPACES
  cf create-space api-staging
  cf create-space api-production
  cf create-space public-staging
  cf create-space public-production
  cf create-space trees-staging

  #REBUILD MIDDLELAYER APPLICATION
  cd fs-middlelayer-api || return

  createMiddlelayerServices api-staging "middlelayer-services-staging.json"
  createMiddlelayerServices api-production "middlelayer-services-production.json"

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
  cd fs-permit-platform || return
fi

createIntakeServices public-production "intake-services-production.json"
createIntakeServices public-staging "intake-services-staging.json"
createIntakeServices trees-staging "intake-services-trees.json"

if $NOT_REBUILD_SERVICE; then
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
  deployFrontEnd master trees-staging
fi
