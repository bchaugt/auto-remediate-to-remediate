#!/bin/bash

USAGE="Usage: $0 [target app name]\n\nExample:\n$0 WebGoat"
TARGETAPP=$1
## PREREQ: echo -n `echo -n your-username:your-servicekey|base64` > authorization.txt
## OR : `echo your-username:your-servicekey|tr -d\\\n|base64` > authorization.txt
CONTRAST_AUTHORIZATION="YnJpYW4uY2hhdUBjb250cmFzdHNlY3VyaXR5LmNvbTo1OEdQQlMzQjUzSkNLVTFW"
## PREREQ: echo -n your-api-key > apikey.txt
CONTRAST_API_KEY="wwEHMnYEIAujE03f"
CONTRAST_ORG="bc6cdc58-2ed7-4068-826a-082d42a07858"
 
BASEURL="https://eval.contrastsecurity.com/Contrast/api/ng/$CONTRAST_ORG"

# Check if all expected arguments were provided
if [[ $# -ne 1 ]]; then
  echo -e $USAGE
  exit 1
fi

# Compose the first part of the API curl command that includes authentication and API key information
CURLCMD="curl -HAccept:application/json -HAPI-Key:$CONTRAST_API_KEY -HAuthorization:$CONTRAST_AUTHORIZATION"

# Get an array of all app IDs where the application definition includes the text $TARGETAPP
declare -a APP_IDS=(`$CURLCMD $BASEURL/applications/filter?filterText=$TARGETAPP | jq -r '.applications[].app_id'`)

# Loop through all found app IDs and get vulnerability traces that have the status of "Auto-Remediated", then change them to "Remediated"
for APP_ID in "${APP_IDS[@]}"
do
  # Get an array of auto-remediated vulnerabilities for the target application
  AUTOREMEDIATED_VULN_IDS=$($CURLCMD $BASEURL/traces/$APP_ID/ids?status=AutoRemediated | jq -r '[.traces[]]')

  # If there are auto-remediated vulnerabilities, then change them to remediated
  if [ $(echo $AUTOREMEDIATED_VULN_IDS | jq '. | length') -gt 0 ]
  then
    $CURLCMD -HContent-Type:application/json -X PUT -d "{\"traces\":$AUTOREMEDIATED_VULN_IDS,\"status\":\"Remediated\"}" $BASEURL/orgtraces/mark
  fi
done