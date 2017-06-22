#!/bin/bash -x


export CATTLE_DB_CATTLE_GO_PARAMS='allowNativePasswords=true&tls=true' # &tls=skip-verify' 
export CATTLE_DB_CATTLE_MYSQL_HOST=${1}
export CATTLE_DB_CATTLE_USERNAME=${2}
export CATTLE_DB_CATTLE_PASSWORD=${3}
export CATTLE_CLUSTER_ADVERTISE_ADDRESS=$(curl -H Metadata:true "http://169.254.169.254/metadata/instance/network/interface/0/ipv4/ipaddress/0/ipaddress?api-version=2017-03-01&format=text")
export CATTLE_DB_CATTLE_MYSQL_NAME='cattle'

export CATTLE_DB_CATTLE_MYSQL_URL="jdbc:mysql://${CATTLE_DB_CATTLE_MYSQL_HOST}:3306/${CATTLE_DB_CATTLE_MYSQL_NAME}?useUnicode=true&characterEncoding=UTF-8&characterSetResults=UTF-8&prepStmtCacheSize=517&cachePrepStmts=true&prepStmtCacheSqlLimit=4096&socketTimeout=60000&connectTimeout=60000&sslServerCert=/var/lib/rancher/etc/ssl/ca.pem&useSSL=true"
export CATTLE_DB_LIQUIBASE_MYSQL_URL=${CATTLE_DB_CATTLE_MYSQL_URL} 



REGISTRY_ADDRESS=${4}
REGISTRY_USERNAME=${5}
REGISTRY_PASSWORD=${6}


# copy SSL
mkdir -p /var/lib/rancher/etc/ssl/
cp ca.pem /var/lib/rancher/etc/ssl/ca.pem


# start server
echo `docker run -d --restart=unless-stopped -p 8080:8080 -p 9345:9345 \
	-e CATTLE_DB_CATTLE_MYSQL_HOST -e CATTLE_DB_CATTLE_USERNAME \
	-e CATTLE_DB_CATTLE_PASSWORD -e CATTLE_DB_CATTLE_MYSQL_NAME  \
    -e CATTLE_DB_CATTLE_GO_PARAMS -e CATTLE_DB_CATTLE_MYSQL_URL  -e CATTLE_DB_LIQUIBASE_MYSQL_URL \
	-v /var/lib/rancher/etc/ssl/ca.pem:/var/lib/rancher/etc/ssl/ca.pem \
	rancher/server --advertise-address ${CATTLE_CLUSTER_ADVERTISE_ADDRESS}`


  # wait until rancher server is ready
  while true; do
    wget -T 5 -c http://${CATTLE_CLUSTER_ADVERTISE_ADDRESS}:8080 && break
    sleep 5
  done

# get env id
ENV_ID=$(docker run -v /tmp:/tmp --rm appropriate/curl -s "http://${CATTLE_CLUSTER_ADVERTISE_ADDRESS}:8080/v2-beta/project?name=${ENV_NAME}" | jq '.data[0].id' | tr -d '"')


function get_registry_id {
echo `docker run \
  -v /tmp:/tmp \
  --rm \
  appropriate/curl \
    -s \
    "http://${CATTLE_CLUSTER_ADVERTISE_ADDRESS}:8080/v2-beta/projects/$ENV_ID/registries/?state=active" \
	|   grep -Eo '[^,]*' |  grep -E  ":\[{\"id\":\"" |  sed 's/\"data\":\[{\"id\":"//' | sed 's/\"//' `
}

REGISTRY_ID=`get_registry_id`

if [ -z $REGISTRY_ID ]
then
echo "Creating Registry $REGISTRY_ADDRESS in Environment $ENV_ID"
 docker run \
  -v /tmp:/tmp \
  --rm \
  appropriate/curl \
 -s \
    -X POST \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
-d "{\"description\":\"Azure Container Registry\",\"name\":\"Azure Container Registry\",\"serverAddress\":\"$REGISTRY_ADDRESS\"}" \
"http://${CATTLE_CLUSTER_ADVERTISE_ADDRESS}:8080/v2-beta/projects/$ENV_ID/registries"

sleep 5

REGISTRY_ID=`get_registry_id`

echo "Creating Registry Credential for registry $REGISTRY_ID"

 docker run \
  -v /tmp:/tmp \
  --rm \
  appropriate/curl \
 -s \
    -X POST \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
-d "{\"email\":\"na\",\"publicValue\":\"$REGISTRY_USERNAME\",\"secretValue\":\"$REGISTRY_PASSWORD\",\"registryId\":\"$REGISTRY_ID\"}" \
"http://${CATTLE_CLUSTER_ADVERTISE_ADDRESS}:8080/v2-beta/projects/$ENV_ID/registryCredentials"

fi

