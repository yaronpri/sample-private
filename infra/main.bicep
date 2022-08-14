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

/* RESOURCE GROUP */
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${prefix}-rg'
  location: location
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
  }
}

/* Create EVENT HUB && EVENT GRID && STORAGE for each step */
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
  }
}]

output deployedsteps array = [for (name, i) in stepsnames: {
  stepname: name
  //sastoken: steps[i].outputs.storage_sas_key
}]
