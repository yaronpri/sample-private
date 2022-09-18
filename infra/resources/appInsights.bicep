@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Application Insights resource name')
param appInsightsName string

@description('log analytic workspace')
param loganalyticWorkspaceResourceId string

@description('Managed identity object id')
param manageidObjId string


resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'microserivces'
  properties: {
    Application_Type: 'other'
    DisableIpMasking: false
    DisableLocalAuth: false
    Flow_Type: 'Bluefield'
    ForceCustomerStorageForProfiler: false
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    WorkspaceResourceId: loganalyticWorkspaceResourceId
  }
}

var monitoringMetricPublisher = '3913510d-42f4-4e42-8a64-420c390055eb'
resource storageDataOwnerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(monitoringMetricPublisher, manageidObjId, applicationInsights.id)
  scope: applicationInsights
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', monitoringMetricPublisher)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

output applicationinsightName string = applicationInsights.name
output applicatioinsightResourceId string = applicationInsights.id
