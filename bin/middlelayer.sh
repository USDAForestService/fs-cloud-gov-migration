#!/bin/bash
source util.sh

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

deployerChanges()
{
  updateDeployementOrgs ${1} "${OLDORG}" "${ORGNAME}" "update deployment to ${ORGNAME}"
  updateDeployementOrgs ${1} ${2} ${3} "update prod space name"
  updateDeployementOrgs ${1} ${4} ${5} "update dev space name"
}
