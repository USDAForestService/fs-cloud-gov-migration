ORGNAME=usda-forest-service

source ./bin/env.sh
source ./bin/util.sh
source ./bin/intake.sh

cf create-space public-trees-staging
createIntakeServices public-trees-staging "../json-envs/intake-services-trees.json" # fyi multi-cups-plugin does not yet work from this function

# Push Intake apps on new org
cd fs-permit-platform
brew install yarn
deployFrontEnd master trees-staging
