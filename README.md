# sample-private

## Setup Azure Components using Bicep (BASH)
region="westeurope"
prefixdeployname="sample01"
deploymentName="$prefixdeployname$region" 

az deployment sub create --name $deploymentName --location $region --template-file ./infra/main.bicep --parameters ./infra/main.parameters.json