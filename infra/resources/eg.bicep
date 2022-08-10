
@description('Provide a prefix name for the system topic.')
param systemtopicname string

@description('Provide a name for the Event Grid subscription.')
param eventsubname string

@description('Resource Id of the eventhub')
param ehresourceid string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Linked storage resource id')
param linkstorageresourceid string

resource systemTopic 'Microsoft.EventGrid/systemTopics@2022-06-15' = {
  name: systemtopicname
  location: location
  properties: {
    source: linkstorageresourceid
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

resource eventSubscription 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2022-06-15' = {
  parent: systemTopic
  name: eventsubname
  properties: {
    destination:{
      endpointType: 'EventHub'
      properties:{
        resourceId: ehresourceid
      }
    }
    filter: {      
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
}
