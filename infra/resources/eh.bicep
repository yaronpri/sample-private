@description('Event Hub Name')
param ehname string

@description('Event Hub Namespace Name')
param ehnamespacename string

@description('Event partition count')
@minValue(1)
@maxValue(100)
param partitioncount int

@description('Event Hub retention days')
param retentiondays int

resource eventhubnamespace 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: ehnamespacename
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = {   
  parent: eventhubnamespace
  name: ehname
  properties: {
    messageRetentionInDays: retentiondays
    partitionCount: partitioncount
  }
}

output eventhubresourceid string = eventHub.id
output eventhubname string = eventHub.name
