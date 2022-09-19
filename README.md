# Sample-eventer-private repo

[![Simulation - CI process](https://github.com/yaronpri/sample-private/actions/workflows/simulator-ci.yml/badge.svg)](https://github.com/yaronpri/sample-private/actions/workflows/simulator-ci.yml)

## Pre-requisite 
Before starting deployment process, execute the following steps in order to use these output as input for the deployment step:
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