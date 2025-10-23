param hubVNet object
param appVNet object

module hubVNetDeployment './virtual-network/main.bicep' = {
  name: '${hubVNet.name}-deployment'
  params: {
    virtualNetworkParams: hubVNet
  }
}

module appVNetDeployment './virtual-network/main.bicep' = {
  name: '${appVNet.name}-deployment'
  params: {
    virtualNetworkParams: appVNet
  }
}

var hubToAppPeeringName = '${hubVNet.name}-to-${appVNet.name}-peering'
module hubToAppPeering './peering/main.bicep' = {
  name: '${hubToAppPeeringName}-deployment'
  params: {
    peeringName: hubToAppPeeringName
    localVnetName: hubVNet.name
    remoteVnetId: appVNetDeployment.outputs.resourceId
    allowForwardedTraffic: true
  }
}

var appToHubPeeringName = '${appVNet.name}-to-${hubVNet.name}-peering'
module appToHubPeering './peering/main.bicep' = {
  name: '${appToHubPeeringName}-deployment'
  params: {
    peeringName: appToHubPeeringName
    localVnetName: appVNet.name
    remoteVnetId: hubVNetDeployment.outputs.resourceId
    allowForwardedTraffic: true
  }
}

output vnets object = {
  hub: {
    name: hubVNet.name
    resourceId: hubVNet.outputs.resourceId
    subnets: {
      firewall: {
        resourceId: hubVNet.outputs.subnetResourceIds[hubVNet.firewallSubnetIndex]
      }
    }
  }
  app: {
    name: appVNet.name
    resourceId: appVNet.outputs.resourceId
    subnets: {
      frontend: {
        resourceId: appVNet.outputs.subnetResourceIds[appVNet.frontendSubnetIndex]
      }
      backend: {
        resourceId: appVNet.outputs.subnetResourceIds[appVNet.backendSubnetIndex]
      }
      firewall: {
        resourceId: appVNet.outputs.subnetResourceIds[appVNet.firewallSubnetIndex]
      }
    }
  }
}
