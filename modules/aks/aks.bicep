param clusterName string
param vnetName string
param appGwName string
param appGwSubnetName string
param aksSubnetName string

// resourceId('Microsoft.Network/applicationGateways', vnetName, aksSubnetName)

resource vnetspokeres 'Microsoft.Network/virtualNetworks@2020-11-01' existing = {
  scope: resourceGroup()
  name: vnetName
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: aksSubnetName
  parent: vnetspokeres
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  name: appGwSubnetName
  parent: vnetspokeres
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-05-01' = {
  name: clusterName
  location: resourceGroup().location
  identity:{
    type: 'SystemAssigned'
  }
  properties: {
    enableRBAC: true
    kubernetesVersion: '1.27.3'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 2
        vmSize: 'Standard_B2s'
        mode: 'System'
        maxCount: 2
        minCount: 1
        maxPods: 50
        enableAutoScaling: true
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnet.id
      }
    ]
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    networkProfile: {
      dnsServiceIP: '10.0.2.10'
      networkPlugin: 'azure'
      serviceCidr: '10.0.2.0/24'
    }
    addonProfiles: {
      ingressApplicationGateway: {
        config: {
          applicationGatewayId: resourceId('Microsoft.Network/applicationGateways', appGwName)
          //applicationGatewayName: appGwName
          //subnetId: gatewaySubnet.id
        }
        enabled: true
      }
    }
    dnsPrefix: 'myaks'
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    servicePrincipalProfile: {    
      clientId: 'msi'
    }
  }
}

output aksClusterName string = aksCluster.name
