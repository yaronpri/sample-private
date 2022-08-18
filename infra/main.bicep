targetScope = 'subscription'

@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param prefix string

@minLength(1)
@description('Containers to create')
param containernames array

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('ACR username secret name in keyvault')
param acradminusernamesecretname string

@description('ACR password secret name in keyvault')
param acrpasswordsecretname string

@description('Event Hub namespace tier')
param eventhubtier string

@description('Event Hub capacity unit')
param ehcapacity int

@description('Event Hub maximum throughput units')
param maximumthroughputunits int

@description('Event Hub partition count')
param partitioncount int

@description('Event Hub retention days')
param retentiondays int

@description('EventHub primarykey secret name in keyvault')
param ehnsprimarykeysecretname string

@description('EventHub connection string secret name in keyvault')
param ehnsconnectionstringsecretname string

@description('Storage primarykey secret name in keyvault')
param storageprimarykeysecretnameprefix string

@description('Storage connection string secret name in keyvault')
param storageconnectionstringsecretnameprefix string

@description('Storage SAS secret name in keyvault')
param storagesassecretnameprefix string

@description('Your AzureAD Object Id')
param userObjectId string

/* RESOURCE GROUP */
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${prefix}-rg'
  location: location
}

/* USER MANAGED IDENTITY */
module identity 'resources/managedidentity.bicep' = {
  name: '${rg.name}-identity'
  scope: rg
  params: {
    location: location
    managedIdentityName: toLower(prefix)
  }
}

/* KEY VAULT */
module keyvault 'resources/kv.bicep' = {
  name: '${rg.name}-keyvault'
  scope: rg
  params: {
    kvname: '${toLower(prefix)}-keyvault'
    skuName: 'standard'
    location: location
    enabledfordeployment: false
    enabledfordiskencryption: false
    enabledfortemplatedeployment: false
    enableSoftDelete: false
    userObjId: userObjectId
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}

/* LOG ANALYTIC WORKSPACE */
module loganalytic 'resources/loganalytic.bicep' = {
  name: '${rg.name}-loganalytic'
  scope: rg
  params: {
    workspaceName: '${toLower(prefix)}-loganalytic-ws'
    location: location
    newResourcePermissions: true
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}

/* APPLICATION INSIGHTS */
module applicationinsights 'resources/appInsights.bicep' = {
  name: '${rg.name}-applicationinsights'
  scope: rg
  params: {
    appInsightsName: '${toLower(prefix)}-applicationinsights'    
    location: location
    loganalyticWorkspaceResourceId: loganalytic.outputs.loganalyticworkspaceresourceid
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}

/* AZURE CONTAINER REGISTRY */
module acr 'resources/acr.bicep' = {
  name: '${rg.name}-acr'
  scope: rg
  params: {
    acrName: '${toLower(prefix)}acr'
    acrSku: 'Basic'
    location: location
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
    kvname: keyvault.outputs.keyvaultname
    acradminusernamesecretname: acradminusernamesecretname
    acrpasswordsecretname: acrpasswordsecretname
  }
}

/* EVENT HUB NAMESPACE */
module eventhubnamespace './resources/ehnamespace.bicep' = {
  name: '${rg.name}-eventhubns'
  scope: rg
  params: {
    ehtier: eventhubtier
    ehnamenamespace: '${toLower(prefix)}-eh-namespace'
    location: rg.location
    ehcapacity: ehcapacity
    maximumthroughputunits: maximumthroughputunits
    kvname: keyvault.outputs.keyvaultname
    ehnsconnectionstringsecretname: ehnsconnectionstringsecretname
    ehnsprimarykeysecretname: ehnsprimarykeysecretname
    manageidObjId: identity.outputs.managedIdentityPrincipalId
  }  
}

/*  EVENT HUB && EVENT GRID && STORAGE for each step */
var stepsnames = ['step1', 'step2', 'step3']

module steps './step.bicep' = [for stepname in stepsnames: { 
  name: '${rg.name}-steps-${stepname}'
  scope: rg
  params: {
    retentiondays: retentiondays
    rgname: rg.name
    location: location
    stepname: stepname
    ehnamespacename: eventhubnamespace.outputs.eventhubnamespacename
    containernames: [
      stepname
    ]
    partitioncount: partitioncount
    prefix: prefix
    kvname: keyvault.outputs.keyvaultname
    storageconnectionstringsecretname: '${storageconnectionstringsecretnameprefix}-${stepname}'
    storageprimarykeysecretname: '${storageprimarykeysecretnameprefix}-${stepname}'
    storagesassecretname: '${storagesassecretnameprefix}-${stepname}'
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}]

/* CHECKPOINT STORAGE */
module checkpointstorage './resources/storage.bicep' = {
  name: '${rg.name}-storage-checkpoint'
  scope: rg
  params: {
    name: '${prefix}checkpoint'
    location: location
    containersarray: stepsnames
    kvname: keyvault.outputs.keyvaultname
    storageconnectionstringsecretname: '${storageconnectionstringsecretnameprefix}-checkpoint'
    storageprimarykeysecretname: '${storageprimarykeysecretnameprefix}-checkpoint'
    storagesassecretname: '${storagesassecretnameprefix}-checkpoint'
    manageidObjId: identity.outputs.managedIdentityPrincipalId 
  }
}

output pipelinesteps array = [for (name, i) in stepsnames: {
  stepname: name
  storageresourceid: steps[i].outputs.storageresourceid
  storageaccountname: steps[i].outputs.storageaccountname
  eventhubresourceid: steps[i].outputs.eventhubresourceid
  eventhubname: steps[i].outputs.eventhubname
  eventgridsystemtopicresourceid: steps[i].outputs.eventgridsystemtopicresourceid
  eventgridsystemtopicname: steps[i].outputs.eventgridsystemtopicname
  eventgridsubscritpionresourceid: steps[i].outputs.eventgridsubscritpionresourceid
  eventgridsubscritpionname: steps[i].outputs.eventgridsubscritpionname
}]
output storagecheckpointresourceid string = checkpointstorage.outputs.storageresourceid
output storagecheckpointaccountname string = checkpointstorage.outputs.storageaccountname
output kevvaultname string = keyvault.outputs.keyvaultname
output kevvaultresourceid string = keyvault.outputs.keyvaultresourceid
output eventhubnamespacename string = eventhubnamespace.outputs.eventhubnamespacename
output eventhubnamespaceresourceid string = eventhubnamespace.outputs.eventhubnamespceid
output managedidentityprincipalid string = identity.outputs.managedIdentityPrincipalId
output managedidentityclientid string = identity.outputs.managedIdentityClientId
output managedidentityresourceid string = identity.outputs.managedIdentityResourceId
output acrname string = acr.outputs.acrname
output acrresourceid string = acr.outputs.acrresourceid
output loganalyticworkspacename string = loganalytic.outputs.loganalyticworkspacename
output loganalyticworkspaceresourceid string = loganalytic.outputs.loganalyticworkspaceresourceid
output applicationinsightsName string = applicationinsights.outputs.applicationinsightName
output applicaitoninsightsresourceid string = applicationinsights.outputs.applicatioinsightResourceId

