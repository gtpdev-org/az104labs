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
param appVNetSubnetFrontendName string
@description('Frontend subnet prefix')
param appVNetSubnetFrontendAddressPrefix string
@description('Backend subnet name')
param appVNetSubnetBackendName string
@description('Backend subnet prefix')
param appVNetSubnetBackendAddressPrefix string
@description('Hub to App VNet peering name')
param hubVNetToAppVNetPeeringName string
@description('App to Hub VNet peering name')
param appVNetToHubVNetPeeringName string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetPrefix
      ]
    }
    subnets: [
      {
        name: firewallSubnetName
        properties: {
          addressPrefix: firewallSubnetPrefix
        }
      }
    ]
  }
}

resource appVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: appVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        appVnetPrefix
      ]
    }
    subnets: [
      {
        name: appVNetSubnetFrontendName
        properties: {
          addressPrefix: appVNetSubnetFrontendAddressPrefix
        }
      }
      {
        name: appVNetSubnetBackendName
        properties: {
          addressPrefix: appVNetSubnetBackendAddressPrefix
        }
      }
    ]
  }
}

resource hubVnetName_hub_to_app_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: hubVNetToAppVNetPeeringName
  properties: {
    remoteVirtualNetwork: {
      id: appVnet.id
    }
    allowVirtualNetworkAccess: true
  }
}

resource appVnetName_app_vnet_to_hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: appVnet
  name: appVNetToHubVNetPeeringName
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
  }
}
