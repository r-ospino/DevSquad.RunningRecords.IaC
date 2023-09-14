targetScope = 'subscription'

param location string = deployment().location
param enviroment string = 'dev'
param rgBaseName string

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  location: location
  name: 'rg-${rgBaseName}-${enviroment}'
}

output rgId string = rg.id
output rgName string = rg.name
