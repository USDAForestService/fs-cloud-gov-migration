#!/bin/bash
freeOldOrgUrl()
{
  cf t -o "${OLDORG}" -s "${1}"
  cf unmap-route "${2}" app.cloud.gov --hostname "${3}"
  cf delete-route -f app.cloud.gov --hostname "${3}"
}

updateDeployementOrgs()
{
  git fetch
  git checkout ${1}
  git push origin ${1}
  REPLACER="s/"${2}"/"${3}"/g"
  sed -i '' $REPLACER './cg-deploy/deploy.sh'
  sed -i '' $REPLACER "./circle.yml"
  git add .
  git commit -m "${4}"
  git push origin "${1}"
}

deleteService()
{
  cf unbind-service "${1}" "${2}"
  cf delete-service "${2}" -f
}

rebuildCupsService() #space #bound-app #service #json
{
  cf t -s "${1}"
  delete-service "${2}" "${3}"
  cf cups "${3}" -p "${4}"
  cf bind-service "${2}" "${3}"
  cf restage "${2}"
}
