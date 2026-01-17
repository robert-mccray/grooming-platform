param location string
param namePrefix string
param environment string
param tags object

var saName = toLower('${namePrefix}${environment}dl${uniqueString(resourceGroup().id)}')
var containerName = 'datalake'

resource sa 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: saName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  tags: tags
  properties: {
    accessTier: 'Hot'
    isHnsEnabled: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: '${sa.name}/default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${sa.name}/default/${containerName}'
  properties: { publicAccess: 'None' }
  dependsOn: [ blob ]
}

output storageAccountName string = sa.name
output storageAccountId string = sa.id
output dataLakeContainerName string = containerName
