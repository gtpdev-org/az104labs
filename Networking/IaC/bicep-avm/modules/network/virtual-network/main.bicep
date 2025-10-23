param virtualNetworkParams object

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${virtualNetworkParams.name}-deployment'
  params: {
    name: virtualNetworkParams.name
    addressPrefixes: virtualNetworkParams.addressPrefixes
    subnets: virtualNetworkParams.subnets
  }
}

output resourceId string = virtualNetwork.outputs.resourceId
output subnetResourceIds array = virtualNetwork.outputs.subnetResourceIds
