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
source ./bin/util.sh
source ./bin/middlelayer.sh
source ./bin/platform.sh

if $NOT_REBUILD_SERVICE; then
  # Download existing apps as sumbmodules
  git submodule add https://github.com/18F/fs-open-forest-platform.git fs-open-forest-platform
  git submodule add https://github.com/18F/fs-open-forest-middlelayer-api.git fs-open-forest-middlelayer-api
  git submodule -q foreach git pull -q origin master #update sumbmodules

  # Login to Cloud Foundry
  cf login --sso -a api.fr.cloud.gov -o ${ORGNAME}

  # CREATE ORG SPACES
  cf create-space middlelayer-staging
  cf create-space middlelayer-production
  cf create-space platform-staging
  cf create-space platform-production

  #REBUILD MIDDLELAYER APPLICATION
  cd fs-open-forest-middlelayer-api || return

  createMiddlelayerServices middlelayer-staging "middlelayer-services-staging.json"
  createMiddlelayerServices middlelayer-production "middlelayer-services-production.json"

  if $FOR_MIGRATION; then
    #Free urls for middlelayer for both production and staging
    freeOldOrgUrl fs-api-staging fs-middlelayer-api-staging fs-middlelayer-api-staging
    freeOldOrgUrl fs-api-prod fs-middlelayer-api fs-middlelayer-api
  fi

  # Update cg-deploy orgs to Org name
  if $FOR_MIGRATION; then
    # On old org-
    deployerChanges dev fs-api-prod middlelayer-production fs-api-staging middlelayer-staging
    deployerChanges master fs-api-prod middlelayer-production fs-api-staging middlelayer-staging
  fi

  # Push app on new org
  cf t -o ${ORGNAME} -s middlelayer-production
  git checkout master
  cf push fs-middlelayer-api -f "./cg-deploy/manifests/manifest.yml"

  cf t -s middlelayer-staging
  git checkout dev
  cf push fs-middlelayer-api-staging -f "./cg-deploy/manifests/manifest-staging.yml"
  cd ..

  # Create bucket for log dumps
 cf t -o ${ORGNAME} -s middlelayer-production
 cf create-service s3 basic log-bucket
 cf create-service-key log-bucket deployer-key

  # CREATE INTAKE SERVICES APP
  cd fs-open-forest-platform || return
fi

createIntakeServices platform-production "intake-services-production.json" ${ORGNAME}
createIntakeServices platform-staging "intake-services-staging.json" ${ORGNAME}

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
  deployFrontEnd master staging
fi
