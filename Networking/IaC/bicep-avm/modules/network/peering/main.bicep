param localVnetName string
param peeringName string
param remoteVnetId string
param allowForwardedTraffic bool = false
param allowGatewayTransit bool = false
param useRemoteGateways bool = false

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-05-01' = {
  name: '${localVnetName}/${peeringName}-peering'
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}
