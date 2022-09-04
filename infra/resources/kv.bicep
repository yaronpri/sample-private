@description('Azure KeyVault Name')
param kvname string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param enabledfordeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param enabledfordiskencryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledfortemplatedeployment bool = false

@description('Enabled soft delete')
param enableSoftDelete bool = false

@description('User Object Id')
param userObjId string

@description('Managed identity object id')
param manageidObjId string

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' = {  
  name: kvname
  location: location
  properties: {
    enabledForDeployment: enabledfordeployment
    enabledForDiskEncryption: enabledfordiskencryption
    enabledForTemplateDeployment: enabledfortemplatedeployment
    enableSoftDelete: enableSoftDelete
    enableRbacAuthorization: true
    tenantId: tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

var kvsecretUser = '4633458b-17de-408a-b874-0445c86b69e6'
resource secretUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvsecretUser, manageidObjId, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvsecretUser)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

var kvadminRole = '00482a5a-887f-4fb3-b363-3b7fe8e74483'
resource adminAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvadminRole, userObjId, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvadminRole)
    principalId: userObjId
    principalType: 'User'
  }
}

var kvownerRole = '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
resource ownerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kvownerRole, userObjId, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvownerRole)
    principalId: userObjId
    principalType: 'User'
  }
}

output keyvaultresourceid string = kv.id
output keyvaultname string = kv.name
