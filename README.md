# Rancher On Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fmarrobi%2FRancherOnAzure%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

### Important
These ARM templates are not supported under any Microsoft support programme or service, and are made available AS IS without warranty of any kind.

<b>Region Restriction:</b> The template is set to deploy using the Azure MySQL service Standard SKU. The MySQL service is currently in public preview and this SKU is currently only available in the “East Asia” region. The SKU can be changed to a Basic SKU but deployment time takes much longer - 60 minutes. This will likely change before the service becomes generally available.

<b>Security</b>: Access control is not configured on initial deployment, when you connect it is recommended you configure access control credentials for Rancher. SSL is not configured for the connection to the Rancher management interface.

## Overview

This template deploys a VM scale set of Rancher Servers and a VM Scale Set of Rancher Cattle hosts. An Azure Container Registry instance is also deployed and credentials added to Rancher. 

## Deployment steps

You can click the "deploy to Azure" button at the beginning of this document.

-	To deploy using the scripts hosted on GitHub leave the artifact parameters set to their defaults. 
-	The Server and Host DNS names must be different and unique.
-	Deployment takes around 20 minutes to deploy with 2 servers and 2 hosts.

#### Connect

Connect to the Rancher deployment using the Rancher URL output, this will be in the format http://dnsname:8080 . 

#### Usage
Scale up of server and hosts has been tested. Scale down will remove hosts but they will remain under management as disconnected.

Traffic is configured to pass through to the Rancher Hosts on ports 80,443,8080. To expose a service configure a Rancher load balancer to listed on one of these ports. 

## Pending work
1.  Add Application Gateway to facilitate SSL offload to the Rancher server
2.	Automatic removal of servers and hosts when scale down

