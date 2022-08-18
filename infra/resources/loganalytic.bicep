@description('Specify the name of the workspace.')
param workspaceName string

@description('Specify the location for the workspace.')
param location string = resourceGroup().location

@description('Specify the pricing tier: PerGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.')
@allowed([
  'CapacityReservation'
  'Free'
  'LACluster'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

@description('Specify the number of days to retain data.')
param retentionInDays int = 30

@description('Specify true to use resource or workspace permissions, or false to require workspace permissions.')
param newResourcePermissions bool

@description('Managed identity object id')
param manageidObjId string


resource workspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: newResourcePermissions
    }
  }
}

var logAnalyticsContributor = '73c42c96-874c-492b-b04d-ab87d138a893'
resource storageDataOwnerAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalyticsContributor, manageidObjId, workspace.id)
  scope: workspace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', logAnalyticsContributor)
    principalId: manageidObjId
    principalType: 'ServicePrincipal'
  }
}

output loganalyticworkspacename string = workspace.name
output loganalyticworkspaceresourceid string = workspace.id
