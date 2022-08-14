@description('Event Hub namespace name')
param ehnamenamespace string

@description('Event Hub tier name')
param ehtier string

@description('Event Hub capacity unit')
param ehcapacity int

@description('Event Hub throughput unit')
param maximumthroughputunits int

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
    isAutoInflateEnabled: true
    maximumThroughputUnits: maximumthroughputunits
  }
}

output eventhubnamespceid string = eventHubNamespace.id
output eventhubnamespacename string = eventHubNamespace.name
