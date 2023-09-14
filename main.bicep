targetScope = 'subscription'

var aksRgBaseName = 'aks'
var hubRgBaseName = 'hub'

module aksrg 'modules/rg/rg.bicep' = {
  name: aksRgBaseName
  params: {
    rgBaseName: aksRgBaseName
    location: deployment().location
  }
}

module hubrg 'modules/rg/rg.bicep' = {
  name: hubRgBaseName
  params: {
    rgBaseName: hubRgBaseName
    location: deployment().location
  }
}
