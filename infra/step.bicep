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
  }
}

module eventgrid './resources/eg.bicep' = {
  name: '${rgname}-eventgrid-${stepname}'  
  params: {    
    systemtopicname: '${toLower(prefix)}-eg-topic-${stepname}'
    eventsubname: '${toLower(prefix)}-eg-sub-${stepname}'
    ehresourceid: eventhub.outputs.ehresourceid
    location: location
    linkstorageresourceid: storage.outputs.storageResourceId
  }
}

/*
param baseTime string = utcNow('u')
var signsasenddate = dateTimeAdd(baseTime, 'P1Y')

#disable-next-line outputs-should-not-contain-secrets
output storage_sas_key string = base64(listAccountSAS(storagenamepredefine,'2022-05-01', 
{
  signedProtocol: 'https'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedServices: 'b'
  signedExpiry: signsasenddate
}))

output storage_account_name string = storage.outputs.storageAccountName
*/
