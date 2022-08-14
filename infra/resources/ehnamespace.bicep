@description('Event Hub namespace name')
param ehnamenamespace string

@description('Event Hub tier name')
param ehtier string

@description('Event Hub capacity unit')
param ehcapacity int

@description('Event Hub throughput unit')
param maximumthroughputunits int

@description('KeyVault name')
param kvname string

@description('EventHub primarykey secret name in keyvault')
param ehnsprimarykeysecretname string

@description('EventHub connection string secret name in keyvault')
param ehnsconnectionstringsecretname string

@description('Azure region for resources')
param location string = resourceGroup().location

resource kv 'Microsoft.KeyVault/vaults@2021-04-01-preview' existing = {  
  name: kvname  
}

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: ehnamenamespace
  location: location
  sku: {
    name: ehtier
    tier:ehtier
    capacity: ehcapacity
  }
  properties: {
    isAutoInflateEnabled: true
    maximumThroughputUnits: maximumthroughputunits
  }
}

resource authorizationRules 'Microsoft.EventHub/namespaces/authorizationRules@2022-01-01-preview' existing = {
  name: 'RootManageSharedAccessKey'
  parent: eventHubNamespace    
}

resource secretehnsprimarykey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: ehnsprimarykeysecretname
  properties: {
    value: authorizationRules.listKeys().primaryKey
  }
}

resource secretehnsconnectionstring 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: kv
  name: ehnsconnectionstringsecretname
  properties: {
    value: authorizationRules.listKeys().primaryConnectionString
  }
}

output eventhubnamespceid string = eventHubNamespace.id
output eventhubnamespacename string = eventHubNamespace.name

