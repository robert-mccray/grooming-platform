targetScope = 'resourceGroup'

param location string = resourceGroup().location
param sqlLocation string = location
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
    location: sqlLocation
    namePrefix: namePrefix
    environment: environment
    tags: tags
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
  }
}

output sqlServerName string = sql.outputs.sqlServerName
output sqlServerLocation string = sql.outputs.sqlServerLocation



module adf './modules/adf.bicep' = {
  name: 'adf'
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    tags: tags
  }
}

