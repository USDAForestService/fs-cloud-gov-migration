#!/bin/bash
# source ./util.sh <- now sourced in migration

createMiddlelayerServices()
{
  cf t -s "${1}"
  cf create-service aws-rds shared-psql fs-api-db
  cf create-service s3 basic fs-api-s3
  cf create-service cloud-gov-service-account space-deployer fs-api-deployer
  cf create-service-key fs-api-deployer circle-ci-"${1}"
  cf service-key fs-api-deployer circle-ci-"${1}"

  cf multi-cups-plugin "${2}"
}

deployerChanges()
{
  updateDeployementOrgs ${1} "${OLDORG}" "${ORGNAME}" "update deployment to ${ORGNAME}"
  updateDeployementOrgs ${1} ${2} ${3} "update prod space name"
  updateDeployementOrgs ${1} ${4} ${5} "update dev space name"
}
