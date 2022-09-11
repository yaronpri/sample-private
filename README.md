# sample-eventer-private

## Setup Azure Components using Bicep (Bash)

``` 
region="westeurope"
deploymentName="sample" 

az deployment sub create --name $deploymentName --location $region --template-file ./infra/main.bicep --parameters ./infra/main.parameters.json
```