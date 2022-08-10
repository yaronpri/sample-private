targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param desc string

@minLength(1)
@description('Containers to create')
param containernames array

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('Event Hub namespace tier')
param eventhubtier string

@description('Event Hub partition count')
param partitioncount int

@description('Event Hub capacity unit')
param ehcapacity int

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${desc}-rg'
  location: location
}

module eventhub './resources/eh.bicep' = {
  name: '${rg.name}-eventhub'
  scope: rg
  params: {
    ehtier: eventhubtier
    ehnamenamespace: '${toLower(desc)}ehnamespace'
    location: rg.location
    ehname: '${toLower(desc)}eh'
    ehcapacity: ehcapacity
    partitioncount: partitioncount
  }
}

module storage './resources/storage.bicep' = {
  name: '${rg.name}-storage'
  scope: rg
  params: {
    name: '${toLower(desc)}step1'
    location: rg.location
    containersarray: containernames
  }
}

module eventgrid './resources/eg.bicep' = {
  name: '${rg.name}-eventgrid'
  scope: rg
  params: {    
    systemtopicname: '${toLower(desc)}egstep1topic'
    eventsubname: '${toLower(desc)}egstep1sub'
    ehresourceid: eventhub.outputs.ehresourceid
    location: rg.location
    linkstorageresourceid: storage.outputs.storageResourceId
  }
}

output resource_group_name string = rg.name
output storage_account_name string = storage.outputs.storageAccountName
