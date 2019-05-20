#!/bin/bash

DEST_DIR=json-envs
SED_REGEX='.*System-Provided:\({.*}\){ "VCAP_APPLICATION":.*'
JQ_FILTER='.VCAP_SERVICES."user-provided" | [ .[] | {name: .name, credentials: .credentials} ]'

get_credentials()
{
  filedir="$DEST_DIR/$3"
  filename="$4.json"

  mkdir -p $filedir

  cf t -s "$1" > /dev/null
  printf "space: %s app: %s file: %s\n" $1 $2 "$filedir/$filename"
  cf env "$2" \
    | tr -d '\n' \
    | sed -n "s/$SED_REGEX/\1/p" \
    | jq "$JQ_FILTER" \
    > "$filedir/$filename"
}

read -p 'This is overwrite all of your existing files in json-envs, are you sure you want to proceed? (y/n): ' response

if [ $response != "y" -a $response != "Y" ]; then
  echo "Exiting"
  exit 0
fi

echo "\nGetting all credentials from Cloud.gov\n"

get_credentials platform-dev           open-forest-platform-api-dev      intake      intake-services-dev
get_credentials platform-staging       open-forest-platform-api-staging  intake      intake-services-staging
get_credentials platform-production    open-forest-platform-api          intake      intake-services-production
get_credentials middlelayer-dev        fs-middlelayer-api-dev            middlelayer middlelayer-services-dev
get_credentials middlelayer-staging    fs-middlelayer-api-staging        middlelayer middlelayer-services-staging
get_credentials middlelayer-production fs-middlelayer-api                middlelayer middlelayer-services-production
