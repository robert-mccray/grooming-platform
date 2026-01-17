targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string
param project string = 'grooming-platform'
param namePrefix string = 'groom'
param tags object = {}

@secure()
param sqlAdminPassword string

param sqlAdminLogin string = 'sqladminuser'

module monitor './modules/monitor.bicep' = {
  name: 'monitor'
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    tags: tags
  }
}

module adls './modules/adls.bicep' = {
  name: 'adls'
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    tags: tags
  }
}

module sql './modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    tags: tags
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

module adf './modules/adf.bicep' = {
  name: 'adf'
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    tags: tags
  }
}

// ---------------------------------------------
// EXISTING STORAGE ACCOUNT (for RBAC scope)
// ---------------------------------------------
resource storageForRbac 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: adls.outputs.storageAccountName
}

// ---------------------------------------------
// ROLE ASSIGNMENT: ADF → Storage Blob Data Contributor
// ---------------------------------------------
resource adfStorageBlobContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Role assignment name MUST be deterministic
  name: guid(
    resourceGroup().id,
    storageForRbac.name,
    adf.outputs.adfName,
    'StorageBlobDataContributor'
  )
  scope: storageForRbac
  properties: {
    principalId: adf.outputs.adfPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalType: 'ServicePrincipal'
  }
}