targetScope = 'resourceGroup'

@description('Prefix name')
param prefix string

@description('Step name')
param stepname string

@minLength(1)
@description('Containers to create')
param containernames array

@description('Event Hub partition count')
param partitioncount int

@description('Event Hub retention days')
param retentiondays int

@description('Resource Group name')
param rgname string

@description('Event Hub Namespace name')
param ehnamespacename string

@description('Deployment location')
param location string

@description('KeyVault name')
param kvname string

@description('Storage primarykey secret name in keyvault')
param storageprimarykeysecretname string

@description('Storage connection string secret name in keyvault')
param storageconnectionstringsecretname string

@description('Storage SAS secret name in keyvault')
param storagesassecretname string


module eventhub './resources/eh.bicep' = {
  name: '${rgname}-eventhub-${stepname}'
  params: {    
    ehname: '${toLower(prefix)}-eh-${stepname}'
    ehnamespacename: ehnamespacename
    partitioncount: partitioncount
    retentiondays: retentiondays
  }
}

var storagenamepredefine = '${toLower(prefix)}${stepname}'

module storage './resources/storage.bicep' = {
  name: '${rgname}-storage-${stepname}'
  params: {
    name: storagenamepredefine
    location: location
    containersarray: containernames
    kvname: kvname
    storageconnectionstringsecretname: storageconnectionstringsecretname
    storageprimarykeysecretname: storageprimarykeysecretname
    storagesassecretname: storagesassecretname
  }
}

module eventgrid './resources/eg.bicep' = {
  name: '${rgname}-eventgrid-${stepname}'  
  params: {    
    systemtopicname: '${toLower(prefix)}-eg-topic-${stepname}'
    eventsubname: '${toLower(prefix)}-eg-sub-${stepname}'
    ehresourceid: eventhub.outputs.eventhubresourceid
    location: location
    linkstorageresourceid: storage.outputs.storageresourceid
  }
}

output storageaccountname string = storage.outputs.storageaccountname
output storageresourceid string = storage.outputs.storageresourceid
output eventhubresourceid string = eventhub.outputs.eventhubresourceid
output eventhubname string = eventhub.outputs.eventhubname
output eventgridsubscritpionresourceid string = eventgrid.outputs.eventgridsubscritpionresourceid
output eventgridsubscritpionname string = eventgrid.outputs.eventgridsubscritpionname
output eventgridsystemtopicresourceid string = eventgrid.outputs.eventgridsystemtopicresourceid
output eventgridsystemtopicname string = eventgrid.outputs.eventgridsystemtopicname
