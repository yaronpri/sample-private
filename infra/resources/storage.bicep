@description('storage name')
param name string

@description('containers to create')
param containersarray array

@description('Azure region for resources')
param location string = resourceGroup().location

@description('KeyVault name')
param kvname string

@description('Storage primarykey secret name in keyvault')
param storageprimarykeysecretname string

@description('Storage connection string secret name in keyvault')
param storageconnectionstringsecretname string

@description('Storage SAS secret name in keyvault')
param storagesassecretname string

param baseTime string = utcNow('u')


resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {  
  name: kvname  
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: name
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
  }
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = [for cname in containersarray: {
  name: '${storage.name}/default/${cname}'
}]

var storageaccesskey = storage.listKeys().keys[0].value
var storageconnstring = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storageaccesskey};EndpointSuffix=core.windows.net'

resource secretstorageprimarykey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: storageprimarykeysecretname
  properties: {
    value: storageaccesskey
  }
}

resource secretstorageconnectionstring 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: storageconnectionstringsecretname
  properties: {
    value: storageconnstring
  }
}

var signsasenddate = dateTimeAdd(baseTime, 'P1Y') //add 1y to current date to create sas valid for 1y
var storagesaskey = storage.listAccountSas('2022-05-01', 
{
  signedProtocol: 'https'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedServices: 'b'
  signedExpiry: signsasenddate
}).accountSasToken


resource secretsas 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: storagesassecretname
  properties: {
    value: storagesaskey
  }
}

output storageaccountname string = storage.name
output storageresourceid string = storage.id
