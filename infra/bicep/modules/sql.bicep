param location string
param namePrefix string
param environment string
param tags object

@secure()
param sqlAdminPassword string
param sqlAdminLogin string = 'sqladminuser'

var sqlServerName = toLower('${namePrefix}-${environment}-sql-${uniqueString(resourceGroup().id)}')
var dbName = '${namePrefix}_${environment}_db'

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    publicNetworkAccess: 'Enabled' // minimal; later you can harden
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServer.name}/${dbName}'
  location: location
  tags: tags
  sku: {
    name: 'Basic' // cheapest; upgrade later
    tier: 'Basic'
  }
  properties: {
    maxSizeBytes: 2147483648
  }
}

output sqlServerName string = sqlServer.name
output sqlDatabaseName string = dbName
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName
