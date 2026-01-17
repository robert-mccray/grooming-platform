param location string
param namePrefix string
param environment string
param tags object

var adfName = '${namePrefix}-${environment}-adf'

resource adf 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

output adfName string = adf.name
output adfPrincipalId string = adf.identity.principalId
