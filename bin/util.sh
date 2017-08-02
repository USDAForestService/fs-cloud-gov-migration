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
