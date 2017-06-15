#!/bin/bash -x


HOST_IP=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipaddress/0/ipaddress?api-version=2017-03-01&format=text")
RANCHER_URL=$1
ENV_NAME='Default'

# lookup s environment id
ENV_ID=$(docker run -v /tmp:/tmp --rm appropriate/curl -s "${RANCHER_URL}/v2-beta/project?name=${ENV_NAME}" | jq '.data[0].id' | tr -d '"')

echo 'Adding host to Rancher Server'

function get_token {
	echo `docker run \
  -v /tmp:/tmp \
  --rm \
  appropriate/curl \
    -s \
    "$RANCHER_URL/v2-beta/projects/$ENV_ID/registrationtokens/?state=active"  |   grep -Eo '[^,]*' |  grep -E  "\"token\":\"" | awk '{ gsub("\"token\":\"", ""); gsub("\"", ""); print}' |
      head -n1 `
}

RANCHER_TOKEN=`get_token`

# if no token create one
if [ -z $RANCHER_TOKEN  ]
then
	docker run \
	  -v /tmp:/tmp \
	  --rm \
	  appropriate/curl \
		-s \
		-X POST \
		-H 'Content-Type: application/json' \
		-H 'accept: application/json' \
		-d "{\"type\":\"registrationToken\"}" \
		  "$RANCHER_URL/v2-beta/projects/$ENV_ID/registrationtoken"
fi

sleep 5

# get token, if still not there wait until is
RANCHER_TOKEN=`get_token`

	while [ -z $RANCHER_TOKEN  ]
	do
		 sleep 5
		 RANCHER_TOKEN=`get_token`
	done

echo "Token: ${RANCHER_TOKEN};"

sudo docker run -e CATTLE_HOST_LABELS="cloud=azure" -e CATTLE_AGENT_IP=${HOST_IP} -d --privileged -v /var/run/docker.sock:/var/run/docker.sock  rancher/agent:latest ${RANCHER_URL}/v1/projects/1a5/scripts/${RANCHER_TOKEN}

