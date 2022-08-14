@description('storage name')
param name string

@description('containers to create')
param containersarray array

@description('Azure region for resources')
param location string = resourceGroup().location

param baseTime string = utcNow('u')
var signsasenddate = dateTimeAdd(baseTime, 'P1Y')

resource storageappdata 'Microsoft.Storage/storageAccounts@2021-09-01' = {
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
  name: '${storageappdata.name}/default/${cname}'
}]

output storageaccountname string = storageappdata.name
output storageresourceid string = storageappdata.id
#disable-next-line outputs-should-not-contain-secrets
output storagesaskey string = storageappdata.listAccountSas('2022-05-01', 
{
  signedProtocol: 'https'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedServices: 'b'
  signedExpiry: signsasenddate
}).accountSasToken
