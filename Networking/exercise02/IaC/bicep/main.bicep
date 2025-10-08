@description('Resource group location')
param location string
@description('Hub VNet name')
param hubVnetName string
@description('Hub VNet address prefix')
param hubVnetPrefix string
@description('Firewall subnet name')
param firewallSubnetName string
@description('Firewall subnet prefix')
param firewallSubnetPrefix string
@description('App VNet name')
param appVnetName string
@description('App VNet address prefix')
param appVnetPrefix string
@description('Frontend subnet name')
param frontendSubnetName string
@description('Frontend subnet prefix')
param frontendSubnetPrefix string
@description('Backend subnet name')
param backendSubnetName string
@description('Backend subnet prefix')
param backendSubnetPrefix string
@description('Hub to App VNet peering name')
param hubToAppVnetPeeringName string
@description('App to Hub VNet peering name')
param appToHubVnetPeeringName string

// Define the Hub VNet
module hubVirtualNetwork 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'hubVirtualNetworkDeployment'
  params: {
    name: hubVnetName
    location: location
    addressPrefixes: [
      hubVnetPrefix
    ]
    subnets: [
      {
        name: firewallSubnetName
        addressPrefix: firewallSubnetPrefix
      }
    ]
  }
}

// Define the App VNet with peering to the Hub VNet
module appVirtualNetwork 'br/public:avm/res/network/virtual-network:0.6.1' = {
  name: 'appVirtualNetworkDeployment'
  params: {
    name: appVnetName
    location: location
    addressPrefixes: [
      appVnetPrefix
    ]
    subnets: [
      {
        name: frontendSubnetName
        addressPrefix: frontendSubnetPrefix
      }
      {
        name: backendSubnetName
        addressPrefix: backendSubnetPrefix
      }
    ]
    peerings: [
      {
        name: appToHubVnetPeeringName
        remotePeeringEnabled: true
        remotePeeringName: hubToAppVnetPeeringName
        remoteVirtualNetworkResourceId: hubVirtualNetwork.outputs.resourceId
      }
    ]
  }
}
