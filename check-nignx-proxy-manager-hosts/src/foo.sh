#!/usr/bin/env bash

#quit on any error
set -euo pipefail

#contains ${Authorization} and ${apiURL}
source .env

#tmp file for json
tmpFi=$(mktemp)

#holds json array of the urls for the services
json=$(curl -s $apiURL -H "Authorization: ${Authorization}" > "${tmpFi}")

#get the amount of json object 
declare -i len=$(($(jq 'length' "${tmpFi}")-1))

#keep track of total down services
declare -i numDown=0 

#iterate over each json object
for i in $(seq 0 ${len}); do
  #get the first domain from array of domains
  domain=$(jq -r ".[${i}].\"domain_names\".[0]" ${tmpFi})

  #make request and search for openresty response
  isBad=$(curl -sm 1 https://${domain} | grep "openresty" || true)

  #if it's an openresty response...
  if [ "${isBad}" != "" ]; then
    #print the domain
    printf "${domain}\n"

    #increment total down
    numDown+=1
  fi
done

#print result
printf "\n${numDown} of $((len+1)) services are down\n"

#remove the temp json file
rm "${tmpFi}"

#make sure temp file is deleted
if (( $? != 0 )); then
  printf "non-zero exit status ($?)"
  printf " when trying to delete temp json file\n"
  printf "file path:  ${tmpFi}"
else
  printf "success\n"
fi
