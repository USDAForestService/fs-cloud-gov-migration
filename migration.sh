
$ORGNAME = usda-forest-service
$OLDORG = gsa-acq-proto

# Import Env vars
source env.sh

# Download existing apps
git clone https://github.com/18F/fs-intake-module.git
git clone https://github.com/18F/fs-middlelayer-api.git

cd fs-middlelayer-api
cf login -sso
cf t -o $ORGNAME

# Create spaces
cf create-space api-staging
cf create-space api-production
cf create-space public-staging
cf create-space public-production


# Create services
# Middlelayer- >

createMiddlelayerServices()
{
cf t -s $1
cf create-service aws-rds shared-psql fs-api-db
cf create-service s3 basic fs-api-s3
cf create-service cloud-gov-service-account space-deployer fs-api-deployer
cf service-key my-service-account fs-api-deployer
cf cups -p nrm-suds-url-service -p {"SUDS_API_URL": $2, "password": $3, "username":$4}
cf cups -p auth-service ADD VALUES
}
createMiddlelayerServices middlelayer-api-staging $NRM_SUDS_URL_SERVICE_PROD_SUDS_API_URL $NRM_SUDS_URL_SERVICE_password $NRM_SUDS_URL_SERVICE_username
createMiddlelayerServices middlelayer-api-production $NRM_SUDS_URL_SERVICE_PROD_SUDS_API_URL $NRM_SUDS_URL_SERVICE_password $NRM_SUDS_URL_SERVICE_username

# On old org-
# Delete old routes
freeOldOrgUrl()
{
cf t -o $OLDORG -s $1
cf unmap-route $2 app.cloud.gov --hostname $3
cf delete-route -f app.cloud.gov --hostname $3
}
#Free urls for middlelayer for both production and staging
freeOldOrgUrl fs-api-staging fs-middlelayer-api-staging fs-middlelayer-api-staging

# Update cg-deploy orgs to Org name
findAndReplace()
{
  for f in $1
  do
    if [ -f $f -a -r $f ]; then
      sed -i "s/$2/$3/g" "$f"
     else
      echo "Error: Cannot read $f"
    fi
  Done
}

updateDeployementOrgs()
{
  git checkout $1
  findAndReplace $3 $4 $5
  git add .
  git commit -m $2
  git push origin $1
}

deployerChanges()
{
  updateDeployementOrgs $1 “update deployment to $ORGNAME” "cg-deploy/*" $OLDORG $ORGNAME
  updateDeployementOrgs $1 “update prod space name” "*" $2 $3
  updateDeployementOrgs $1 “update dev space name” "*" $4 $5
}
deployerChanges dev fs-api-prod api-production fs-api-staging api-staging
deployerChanges master fs-api-prod api-production fs-api-staging api-staging


# Push app on new org
cf t -o $ORGNAME -s api-production
git checkout master # not sure if this makes sense
cf push fs-middlelayer-api -f "./cg-deploy/manifests/manifest.yml"

cf t -s api-staging
cf push middlelayer-api-staging -f "./cg-deploy/manifests/manifest-staging.yml"

# Intake
cd ..
cd fs-intake-module
createIntakeServices()
{
cf t -s $1
cf create-service aws-rds shared-psql intake-db
cf create-service s3 basic intake-s3
cf create-service cloud-gov-service-account space-deployer intake-deployer
cf service-key my-service-account intake-deployer
cf cups -p middlelayer-service -p
cf cups -p intake-auth-service $3 ADD VALUES
}

createIntakeServices intake-staging Middlelayer-service-values Intake-service-values
createIntakeServices intake-staging Middlelayer-service-values Intake-service-values
