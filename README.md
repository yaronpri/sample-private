# Sample-eventer-private repo

[![Simulation - CI process](https://github.com/yaronpri/sample-private/actions/workflows/simulator-ci.yml/badge.svg)](https://github.com/yaronpri/sample-private/actions/workflows/simulator-ci.yml)

## Pre-requisite 
Before starting deployment process, execute the following steps in order to use these output as input for the deployment step:
   - FORK this repo !
   - Generate ssh key, example for mac: 
   ```
   ssh-keygen -t rsa -m PEM
   ```
   - Retrieve the Azure AD User - object id - which will get a full access to Azure KeyVault which created during the deployment process, you can get it via portal


## IaC deployment using Bicep (Bash)
``` 
region="westeurope"
deploymentName="sample" 

az deployment sub create --name $deploymentName --location $region --template-file ./infra/main.bicep --parameters ./infra/main.parameters.json
```

## Continous Integration
Each project under /code folder contain a Dockerfile to build the concrete project.
GitHub Actions was defined for each of this projects to be executed once a 'push' operation was done to one of these folders.
The docker image of each project pushed to Azure Container Registry which created in previous step.
Execute the following steps in order to make it work in your environment:
### Create Service Principal for GitHub Actions
Create a service principal to access your resource group with the Contributor role using the following command, replacing:
<SUBSCRIPTION_ID> with the subscription ID of your Azure account
<RESOURCE_GROUP> with the name of the resource group where your ACR is located
```
az ad sp create-for-rbac \
    --name "ghActionAzureEventerim" \
    --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
    --role Contributor \
    --sdk-auth
```

Save the output of previous commadn as GtHub REPO secret name it: 'AZURE_CREDENTIALS' 
### Get the ACR details
   In GitHub repo Create the following secrets (go to -> 'settings -> secrets -> actions'):
   - REGISTRY_LOGIN_SERVER -> from created Azure Container Registry copy the 'login server' URI
   - REGISTRY_USERNAME -> from created Azure KeyVault get the value of the following secret: acradminusername
   - REGISTRY_PASSWORD -> from created Azure KeyVault get the value of the following secret: acradminpassword

### 
   