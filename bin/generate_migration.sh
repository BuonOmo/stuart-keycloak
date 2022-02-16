# #! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'

MIGRATION_NAME=${1}

if [ -z ${MIGRATION_NAME} ]; then
  echo "${RED}Migration name is missing. Use `basename $0` -h to see usage.'"
  exit 128
elif [ "$#" -gt  "1" ]; then
  echo "${RED}Migration name invalid. Use `basename $0` -h to see usage."
  exit 128
elif [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` [migration_name]"
  echo "migration_name has to be snake_cased, can't contain digits nor whitespaces."
  exit 0
elif [[ -z ${MIGRATION_NAME//[_[:lower:]]} ]]; then
  TIMESTAMP=`date +"%Y%m%d%H%M%S"`
  FNAME="./keycloak_config/migrations/${TIMESTAMP}_${MIGRATION_NAME}.json"

  touch $FNAME
  echo "{}" >> $FNAME

  if test -f "$FNAME"; then
    echo "${GREEN}Migration file ${MIGRATION_NAME} created under ${FNAME}"
    exit 0
  else
    echo "${RED}Migration file ${MIGRATION_NAME} couldn't be created"
    exit 126
  fi
else
  echo "${RED}Migration name is invalid, please follow snake_case. Use `basename $0` -h to see usage."
  exit 128
fi