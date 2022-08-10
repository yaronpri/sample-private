@description('Event Hub namespace name')
param ehnamenamespace string

@description('Event Hub namespace name')
param ehtier string

@description('Event Hub name')
param ehname string

@description('Event Hub partition count')
param partitioncount int

@description('Event Hub capacity unit')
param ehcapacity int

@description('Azure region for resources')
param location string = resourceGroup().location

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: ehnamenamespace
  location: location
  sku: {
    name: ehtier
    tier:ehtier
    capacity: ehcapacity
  }
  properties: {
    isAutoInflateEnabled: false
    maximumThroughputUnits: 0
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {
  parent: eventHubNamespace
  name: ehname
  properties: {
    messageRetentionInDays: 7
    partitionCount: partitioncount
  }
}

output ehresourceid string = eventHub.id
