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
@description('ASG name for frontend subnet')
param asgName string
@description('NSG name for backend subnet')
param nsgName string
@description('VM size for both VMs')
param vmSize string
@description('VM image publisher')
param imagePublisher string
@description('VM image offer')
param imageOffer string
@description('VM image sku')
param imageSku string
@description('VM image version')
param imageVersion string
@description('OS disk size in GB')
param osDiskSizeGb int
@description('OS disk type')
param osDiskType string
@description('OS disk caching')
param osDiskCaching string
@description('OS disk create option')
param osDiskCreateOption string
@description('OS disk delete option')
param osDiskDeleteOption string
@description('VM admin username')
param adminUsername string
@description('VM admin password')
@secure()
param adminPassword string
@description('VM1 name')
param vm1Name string
@description('VM2 name')
param vm2Name string
@description('VM1 public IP name')
param vm1PublicIpName string
@description('VM2 public IP name')
param vm2PublicIpName string
@description('VM1 NIC name')
param vm1NicName string
@description('VM2 NIC name')
param vm2NicName string
@description('NSG rule name')
param nsgRuleName string
@description('NSG rule priority')
param nsgRulePriority int
@description('NSG rule direction')
param nsgRuleDirection string
@description('NSG rule access')
param nsgRuleAccess string
@description('NSG rule protocol')
param nsgRuleProtocol string
@description('NSG rule source address prefix')
param nsgRuleSourceAddressPrefix string
@description('NSG rule source port range')
param nsgRuleSourcePortRange string
@description('NSG rule destination port range')
param nsgRuleDestinationPortRange string

// Hub VNet
module hubVNet 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: hubVnetName
  params: {
    name: hubVnetName
    addressPrefixes: [hubVnetPrefix]
    subnets: [
      {
        name: firewallSubnetName
        addressPrefix: firewallSubnetPrefix
      }
    ]
  }
}

// App VNet
module appVNet 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: appVnetName
  params: {
    name: appVnetName
    addressPrefixes: [appVnetPrefix]
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
        remoteVirtualNetworkResourceId: hubVNet.outputs.resourceId
      }
    ]
  }
}

// Application Security Group for frontend subnet
module appAsg 'br/public:avm/res/network/application-security-group:0.2.1' = {
  name: asgName
  params: {
    name: asgName
  }
}

// Network Security Group for backend subnet
module backendNsg 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: nsgName
  params: {
    name: nsgName
    securityRules: [
      {
        name: nsgRuleName
        properties: {
          access: nsgRuleAccess
          direction: nsgRuleDirection
          priority: nsgRulePriority
          protocol: nsgRuleProtocol
          destinationApplicationSecurityGroupResourceIds: [appAsg.outputs.resourceId]
          destinationPortRange: nsgRuleDestinationPortRange
          sourceAddressPrefix: nsgRuleSourceAddressPrefix
          sourcePortRange: nsgRuleSourcePortRange
        }
      }
    ]
  }
}

// VM1 (frontend)
module vm1 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: vm1Name
  params: {
    name: vm1Name
    availabilityZone: -1
    vmSize: vmSize
    computerName: vm1Name
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDisk: {
      name: '${vm1Name}-osdisk'
      caching: osDiskCaching
      createOption: osDiskCreateOption
      deleteOption: osDiskDeleteOption
      diskSizeGB: osDiskSizeGb
      managedDisk: {
        storageAccountType: osDiskType
      }
    }
    imageReference: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSku
      version: imageVersion
    }
    osType: 'Linux'
    nicConfigurations: [
      {
        name: vm1NicName
        ipConfigurations: [
          {
            name: '${vm1NicName}-ipconfig'
            subnetResourceId: appVNet.outputs.subnetResourceIds[0]
            applicationSecurityGroups: [
              { id: appAsg.outputs.resourceId }
            ]
            pipConfiguration: {
              name: vm1PublicIpName
              location: location
              skuName: 'Standard'
              publicIPAllocationMethod: 'Static'
            }
          }
        ]
      }
    ]
  }
}

// VM2 (backend)
module vm2 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: vm2Name
  params: {
    name: vm2Name
    availabilityZone: -1
    vmSize: vmSize
    computerName: vm2Name
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDisk: {
      name: '${vm2Name}-osdisk'
      caching: osDiskCaching
      createOption: osDiskCreateOption
      deleteOption: osDiskDeleteOption
      diskSizeGB: osDiskSizeGb
      managedDisk: {
        storageAccountType: osDiskType
      }
    }
    imageReference: {
      publisher: imagePublisher
      offer: imageOffer
      sku: imageSku
      version: imageVersion
    }
    osType: 'Linux'
    nicConfigurations: [
      {
        name: vm2NicName
        networkSecurityGroupResourceId: backendNsg.outputs.resourceId
        ipConfigurations: [
          {
            name: '${vm2NicName}-ipconfig'
            subnetResourceId: appVNet.outputs.subnetResourceIds[1] // Backend subnet
            pipConfiguration: {
              name: vm2PublicIpName
              location: location
              skuName: 'Standard'
              publicIPAllocationMethod: 'Static'
            }
          }
        ]
      }
    ]
  }
}
