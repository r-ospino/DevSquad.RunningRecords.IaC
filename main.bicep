targetScope = 'subscription'

param environment string = 'dev'
param location string = deployment().location

param aksVNetAddressPrefixes array = [
  '10.1.0.0/16'
]

param hubVNETaddPrefixes array = [
  '10.0.0.0/16'
]
param hubVNETdefaultSubnet object = {
  properties: {
    addressPrefix: '10.0.0.0/24'
  }
  name: 'default'
}
param hubVNETfirewalSubnet object = {
  properties: {
    addressPrefix: '10.0.1.0/24'
  }
  name: 'AzureFirewallSubnet'
}
param hubVNETVMSubnet object = {
  properties: {
    addressPrefix: '10.0.2.0/28'
  }
  name: 'vmsubnet'
}
param hubVNETBastionSubnet object = {
  properties: {
    addressPrefix: '10.0.3.0/27'
  }
  name: 'AzureBastionSubnet'
}

var aksRgName = 'rg-aks-${environment}'
var hubRgName = 'rg-hub-${environment}'

module aksrg 'modules/rg/rg.bicep' = {
  name: aksRgName
  params: {
    rgName: aksRgName
    location: location
  }
}

module hubrg 'modules/rg/rg.bicep' = {
  name: hubRgName
  params: {
    rgName: hubRgName
    location: location
  }
}

module aksvnet 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(aksrg.name)
  name: 'aks-VNet'
  params: {
    environment: environment
    location: location
    vnetAddressSpace: {
        addressPrefixes: aksVNetAddressPrefixes 
    }
    vNetBaseName: 'aks'
    subnets: [
      {
        properties: {
          addressPrefix: '10.1.2.0/23'
          privateEndpointNetworkPolicies: 'Disabled'
          routeTable: {
            id: routetable.outputs.routetableID
          }          
        }
        name: 'AKS'
      }
    ]
  }
  dependsOn: [
    aksrg
  ]
}

module vnethub 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'hub-VNet'
  params: {
    environment: environment
    location: location
    vnetAddressSpace: {
        addressPrefixes: hubVNETaddPrefixes
    }
    vNetBaseName: 'hub'
    subnets: [
      hubVNETdefaultSubnet
      hubVNETfirewalSubnet
      hubVNETVMSubnet
      hubVNETBastionSubnet
    ]
  }
  dependsOn: [
    hubrg
  ]
}

module vnetpeeringhub 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(hubrg.name)
  name: 'vnetpeering'
  params: {
    peeringName: 'HUB-to-Spoke'
    vnetName: vnethub.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: aksvnet.outputs.vnetId
      }
    }    
  }
}

module vnetpeeringspoke 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(aksrg.name)
  name: 'vnetpeeringspoke'
  params: {
    peeringName: 'Spoke-to-HUB'
    vnetName: aksvnet.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnethub.outputs.vnetId
      }
    }    
  }
}

module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(aksrg.name)
  name: 'aks-udr'
  params: {
    rtName: 'aks-udr'
  } 
}

