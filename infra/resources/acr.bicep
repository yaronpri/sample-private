@minLength(5)
@maxLength(50)
@description('Provide a globally unique name of your Azure Container Registry')
param acrName string = 'acr${uniqueString(resourceGroup().id)}'

@description('Provide a location for the registry.')
param location string = resourceGroup().location

@description('Provide a tier of your Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Basic'

@description('KeyVault name')
param kvname string

@description('ACR admin UserName secret name in keyvault')
param acradminusernamesecretname string

@description('ACR admin password secret name in keyvault')
param acrpasswordsecretname string

@description('Managed identity object id')
param manageidObjId string

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {  
  name: kvname  
}

resource acrResource 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
  }
}

var acrPullRole = '7f951dda-4ed3-4680-a7ca-43fe172d538d'
resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrPullRole, manageidObjId, acrResource.id)
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRole)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

var acrPushRole = '8311e382-0749-4cb8-b61a-304f252e45ec'
resource acrPushAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrPushRole, manageidObjId, acrResource.id)
  scope: acrResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPushRole)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

var acradminuser = acrResource.listCredentials().username
var acradminpassword = acrResource.listCredentials().passwords[0].value


resource secretAcrUserName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: acradminusernamesecretname
  properties: {
    value: acradminuser
  }
}

resource secretAcrUserPassword 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: acrpasswordsecretname
  properties: {
    value: acradminpassword
  }
}

output acrname string = acrResource.name
output acrresourceid string = acrResource.id
