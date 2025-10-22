@description('Access for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshAccess string
@description('Destination port range for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshDestinationPortRange string
@description('Direction for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshDirection string
@description('Name for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshName string
@description('Priority for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshPriority int
@description('Protocol for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshProtocol string
@description('Source address prefix for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshSourceAddressPrefix string
@description('Source port range for NSG rule to allow SSH')
param appVNetNsgRuleAllowSshSourcePortRange string
@description('Name of backend NSG for App VNet')
param appVNetNsgName string
@description('Name of the Application Security Group for frontend subnet')
param appVNetAsgName string
@description('Name of App VNet')
param appVnetName string
@description('Address prefix for App VNet')
param appVnetPrefix string
@description('Backend subnet address prefix for App VNet')
param appVNetSubnetBackendAddressPrefix string
@description('Backend subnet name for App VNet')
param appVNetSubnetBackendName string
@description('Firewall subnet address prefix for App VNet')
param appVNetSubnetFirewallAddressPrefix string
@description('Firewall subnet name for App VNet')
param appVNetSubnetFirewallName string
@description('Frontend subnet address prefix for App VNet')
param appVNetSubnetFrontendAddressPrefix string
@description('Frontend subnet name for App VNet')
param appVNetSubnetFrontendName string
@description('Name of the App VNet firewall')
param appVNetFirewallName string
@description('SKU tier for App VNet firewall')
param appVNetFirewallSkuTier string
@description('Name of App VNet firewall policy')
param appVNetFirewallPolicyName string
@description('Action for Application Rule Collection in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionAction string
@description('AllowAzurePipelines name for Application Rule Collection in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesName string
@description('Protocols for AllowAzurePipelines in Application Rule Collection')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesProtocols array
@description('Rule type for AllowAzurePipelines in Application Rule Collection')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesRuleType string
@description('Source addresses for AllowAzurePipelines in Application Rule Collection')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesSourceAddresses array
@description('Target FQDNs for AllowAzurePipelines in Application Rule Collection')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesTargetFqdns array
@description('Terminate TLS for AllowAzurePipelines in Application Rule Collection')
param appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesTerminateTLS bool
@description('Name of Application Rule Collection Group in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionGroupName string
@description('Priority of Application Rule Collection Group in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionGroupPriority int
@description('Name of Application Rule Collection in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionName string
@description('Priority of Application Rule Collection in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionPriority int
@description('Rule collection type for Application Rule Collection in firewall policy')
param appVNetFirewallPolicyApplicationRuleCollectionType string
@description('Action for Network Rule Collection in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionAction string
@description('Destination addresses for AllowDns in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsDestinationAddresses array
@description('Destination ports for AllowDns in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsDestinationPorts array
@description('IP protocols for AllowDns in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsIpProtocols array
@description('Name of AllowDns rule in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsName string
@description('Rule type for AllowDns in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsRuleType string
@description('Source addresses for AllowDns in Network Rule Collection')
param appVNetFirewallPolicyNetworkRuleCollectionAllowDnsSourceAddresses array
@description('Name of Network Rule Collection Group in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionGroupName string
@description('Priority of Network Rule Collection Group in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionGroupPriority int
@description('Name of Network Rule Collection in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionName string
@description('Priority of Network Rule Collection in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionPriority int
@description('Rule collection type for Network Rule Collection in firewall policy')
param appVNetFirewallPolicyNetworkRuleCollectionType string
@description('SKU tier for App VNet firewall policy')
param appVNetFirewallPolicySkuTier string
@description('Name of App VNet firewall public IP')
param appVNetFirewallPublicIpName string
@description('Name of Private DNS Zone for App VNet')
param appVNetPrivateDnsZoneName string
@description('Name of the route table for App VNet firewall')
param appVNetRouteTableName string
@description('Name of the outbound route for the App VNet firewall route table')
param appVNetRouteTableOutboundRouteName string
@description('Address prefix for the outbound route for the App VNet firewall route table')
param appVNetRouteTableOutboundRouteAddressPrefix string
@description('Next Hop Type for the outbound route for the App VNet firewall route table')
param appVNetRouteTableOutboundRouteNextHopType string
@description('Name of hub VNet')
param hubVnetName string
@description('Address prefix for hub VNet')
param hubVnetPrefix string
@description('Name of hub VNet firewall subnet')
param hubVNetFirewallSubnetName string
@description('Address prefix for hub VNet firewall subnet')
param hubVNetFirewallSubnetPrefix string
@description('Resource group location')
param location string
@description('Allow forwarded traffic in VNet peering')
param networkingPeeringsAllowForwardedTraffic bool
@description('Name of App to Hub VNet peering')
param networkingPeeringsAppToHubName string
@description('Name of Hub to App VNet peering')
param networkingPeeringsHubToAppName string
@description('Allocation method for public IP')
param publicIpAllocationMethod string
@description('SKU name for public IP')
param publicIpSkuName string
@description('SKU tier for public IP')
param publicIpSkuTier string
@description('IP version for public IP')
param publicIpVersion string
@description('VM1 name')
param vm1Name string
@description('VM1 NIC name')
param vm1NicName string
@description('VM1 public IP name')
param vm1PublicIpName string
@description('VM2 name')
param vm2Name string
@description('VM2 NIC name')
param vm2NicName string
@description('VM2 public IP name')
param vm2PublicIpName string
@description('VM image offer')
param vmImageOffer string
@description('VM image publisher')
param vmImagePublisher string
@description('VM image sku')
param vmImageSku string
@description('VM image version')
param vmImageVersion string
@description('OS disk caching')
param vmOsDiskCaching string
@description('OS disk create option')
param vmOsDiskCreateOption string
@description('OS disk delete option')
param vmOsDiskDeleteOption string
@description('OS disk OS type')
param vmOsDiskOsType string
@description('OS disk size in GB')
param vmOsDiskSizeGb int
@description('OS disk type')
param vmOsDiskType string
@description('VM size for both VMs')
param vmSize string

// Not provided in parameters file
@description('Admin username for virtual machines')
param adminUsername string
@description('Admin password for virtual machines')
@secure()
param adminPassword string
@description('No availability zones')
var noAvailabilityZones int = -1

// Hub VNet
module hubVNet 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${hubVnetName}-deployment'
  params: {
    name: hubVnetName
    addressPrefixes: [hubVnetPrefix]
    subnets: [
      {
        name: hubVNetFirewallSubnetName
        addressPrefix: hubVNetFirewallSubnetPrefix
      }
    ]
  }
}

// App VNet
module appVNet 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${appVnetName}-deployment'
  params: {
    name: appVnetName
    addressPrefixes: [appVnetPrefix]
    subnets: [
      {
        name: appVNetSubnetFrontendName
        addressPrefix: appVNetSubnetFrontendAddressPrefix
      }
      {
        name: appVNetSubnetBackendName
        addressPrefix: appVNetSubnetBackendAddressPrefix
      }
      {
        name: appVNetSubnetFirewallName
        addressPrefix: appVNetSubnetFirewallAddressPrefix
      }
    ]
    peerings: [
      {
        name: networkingPeeringsAppToHubName
        remotePeeringEnabled: true
        remotePeeringName: networkingPeeringsHubToAppName
        remoteVirtualNetworkResourceId: hubVNet.outputs.resourceId
        allowForwardedTraffic: networkingPeeringsAllowForwardedTraffic
      }
    ]
  }
}
var appVNetResourceId = appVNet.outputs.resourceId
var appVNetFrontendSubnetResourceId = appVNet.outputs.subnetResourceIds[0]
var appVNetBackendSubnetResourceId = appVNet.outputs.subnetResourceIds[1]

// Firewall policy for App VNet
module appVNetFirewallPolicy 'br/public:avm/res/network/firewall-policy:0.3.1' = {
  name: '${appVNetFirewallPolicyName}-deployment'
  params: {
    name: appVNetFirewallPolicyName
    tier: appVNetFirewallPolicySkuTier
    ruleCollectionGroups: [
      {
        name: appVNetFirewallPolicyApplicationRuleCollectionGroupName
        priority: appVNetFirewallPolicyApplicationRuleCollectionGroupPriority
        ruleCollections: [
          {
            action: {
              type: appVNetFirewallPolicyApplicationRuleCollectionAction
            }
            name: appVNetFirewallPolicyApplicationRuleCollectionName
            priority: appVNetFirewallPolicyApplicationRuleCollectionPriority
            ruleCollectionType: appVNetFirewallPolicyApplicationRuleCollectionType
            rules: [
              {
                name: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesName
                ruleType: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesRuleType
                targetFqdns: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesTargetFqdns
                protocols: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesProtocols
                sourceAddresses: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesSourceAddresses
                terminateTLS: appVNetFirewallPolicyApplicationRuleCollectionAllowAzurePipelinesTerminateTLS
              }
            ]
          }
        ]
      }
      {
        name: appVNetFirewallPolicyNetworkRuleCollectionGroupName
        priority: appVNetFirewallPolicyNetworkRuleCollectionGroupPriority
        ruleCollections: [
          {
            action: {
              type: appVNetFirewallPolicyNetworkRuleCollectionAction
            }
            name: appVNetFirewallPolicyNetworkRuleCollectionName
            priority: appVNetFirewallPolicyNetworkRuleCollectionPriority
            ruleCollectionType: appVNetFirewallPolicyNetworkRuleCollectionType
            rules: [
              {
                name: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsName
                ruleType: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsRuleType
                destinationAddresses: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsDestinationAddresses
                destinationPorts: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsDestinationPorts
                ipProtocols: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsIpProtocols
                sourceAddresses: appVNetFirewallPolicyNetworkRuleCollectionAllowDnsSourceAddresses
              }
            ]
          }
        ]
      }
    ]
  }
}
var appVNetFirewallPolicyResourceId = appVNetFirewallPolicy.outputs.resourceId

// Firewall for App VNet
module appVNetFirewall 'br/public:avm/res/network/azure-firewall:0.6.1' = {
  name: '${appVNetFirewallName}-deployment'
  params: {
    name: appVNetFirewallName
    location: location
    azureSkuTier: appVNetFirewallSkuTier
    virtualNetworkResourceId: appVNetResourceId
    firewallPolicyId: appVNetFirewallPolicyResourceId
    publicIPAddressObject: {
      name: appVNetFirewallPublicIpName
      publicIpAddressVersion: publicIpVersion
      publicIpAllocationMethod: publicIpAllocationMethod
      skuName: publicIpSkuName
      skuTier: publicIpSkuTier
    }
  }
}
var appVNetFirewallPrivateIpAddress = appVNetFirewall.outputs.privateIp


// Application Security Group for frontend subnet
module appAsg 'br/public:avm/res/network/application-security-group:0.2.1' = {
  name: '${appVNetAsgName}-deployment'
  params: {
    name: appVNetAsgName
  }
}
var frontendApplicationSecurityGroupResourceId = appAsg.outputs.resourceId

// Network Security Group for backend subnet
module backendNsg 'br/public:avm/res/network/network-security-group:0.5.1' = {
  name: '${appVNetNsgName}-deployment'
  params: {
    name: appVNetNsgName
    securityRules: [
      {
        name: appVNetNsgRuleAllowSshName
        properties: {
          access: appVNetNsgRuleAllowSshAccess
          direction: appVNetNsgRuleAllowSshDirection
          priority: appVNetNsgRuleAllowSshPriority
          protocol: appVNetNsgRuleAllowSshProtocol
          destinationApplicationSecurityGroupResourceIds: [frontendApplicationSecurityGroupResourceId]
          destinationPortRange: appVNetNsgRuleAllowSshDestinationPortRange
          sourceAddressPrefix: appVNetNsgRuleAllowSshSourceAddressPrefix
          sourcePortRange: appVNetNsgRuleAllowSshSourcePortRange
        }
      }
    ]
  }
}
var backendNetworkSecurityGroupResourceId = backendNsg.outputs.resourceId

// Route Table for App VNet firewall
module appVNetRouteTable 'br/public:avm/res/network/route-table:0.1.0' = {
  name: '${appVNetRouteTableName}-deployment'
  params: {
    name: appVNetRouteTableName
    routes: [
      {
        name: appVNetRouteTableOutboundRouteName
        properties: {
          addressPrefix: appVNetRouteTableOutboundRouteAddressPrefix
          nextHopIpAddress: appVNetFirewallPrivateIpAddress
          nextHopType: appVNetRouteTableOutboundRouteNextHopType
        }
      }
    ]
  }
}
var appVNetRouteTableResourceId = appVNetRouteTable.outputs.resourceId

// Associate Route Table to frontend subnet
module appVNetRouteTableAssociateFrontendSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.3' = {
  name: '${appVNetSubnetFrontendName}-subnet-association'
  params: {
    name: appVNetSubnetFrontendName
    virtualNetworkName: appVnetName
    addressPrefix: appVNetSubnetFrontendAddressPrefix
    routeTableResourceId: appVNetRouteTableResourceId
  }
}

// Associate Route Table to backend subnet
module appVNetRouteTableAssociateBackendSubnet 'br/public:avm/res/network/virtual-network/subnet:0.1.3' = {
  name: '${appVNetSubnetBackendName}-subnet-association'
  params: {
    name: appVNetSubnetBackendName
    virtualNetworkName: appVnetName
    addressPrefix: appVNetSubnetBackendAddressPrefix
    routeTableResourceId: appVNetRouteTableResourceId
  }
  dependsOn: [
    appVNetRouteTableAssociateFrontendSubnet
  ]
}

// VM1 (frontend)
module vm1 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: '${vm1Name}-deployment'
  params: {
    name: vm1Name
    availabilityZone: noAvailabilityZones
    vmSize: vmSize
    computerName: vm1Name
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDisk: {
      name: '${vm1Name}-osdisk'
      caching: vmOsDiskCaching
      createOption: vmOsDiskCreateOption
      deleteOption: vmOsDiskDeleteOption
      diskSizeGB: vmOsDiskSizeGb
      managedDisk: {
        storageAccountType: vmOsDiskType
      }
    }
    imageReference: {
      publisher: vmImagePublisher
      offer: vmImageOffer
      sku: vmImageSku
      version: vmImageVersion
    }
    osType: vmOsDiskOsType
    nicConfigurations: [
      {
        name: vm1NicName
        ipConfigurations: [
          {
            name: '${vm1NicName}-ipconfig'
            subnetResourceId: appVNetFrontendSubnetResourceId
            applicationSecurityGroups: [
              { id: frontendApplicationSecurityGroupResourceId }
            ]
            pipConfiguration: {
              name: vm1PublicIpName
              location: location
              skuName: publicIpSkuName
              skuTier: publicIpSkuTier
              publicIPAddressVersion: publicIpVersion
              publicIPAllocationMethod: publicIpAllocationMethod
            }
          }
        ]
      }
    ]
  }
}
var vm1PrivateIpAddress = vm1.outputs.nicConfigurations[0].?ipConfigurations[0].?privateIP

// VM2 (backend)
module vm2 'br/public:avm/res/compute/virtual-machine:0.20.0' = {
  name: '${vm2Name}-deployment'
  params: {
    name: vm2Name
    availabilityZone: noAvailabilityZones
    vmSize: vmSize
    computerName: vm2Name
    adminUsername: adminUsername
    adminPassword: adminPassword
    osDisk: {
      name: '${vm2Name}-osdisk'
      caching: vmOsDiskCaching
      createOption: vmOsDiskCreateOption
      deleteOption: vmOsDiskDeleteOption
      diskSizeGB: vmOsDiskSizeGb
      managedDisk: {
        storageAccountType: vmOsDiskType
      }
    }
    imageReference: {
      publisher: vmImagePublisher
      offer: vmImageOffer
      sku: vmImageSku
      version: vmImageVersion
    }
    osType: 'Linux'
    nicConfigurations: [
      {
        name: vm2NicName
        networkSecurityGroupResourceId: backendNetworkSecurityGroupResourceId
        ipConfigurations: [
          {
            name: '${vm2NicName}-ipconfig'
            subnetResourceId: appVNetBackendSubnetResourceId
            pipConfiguration: {
              name: vm2PublicIpName
              location: location
              skuName: publicIpSkuName
              publicIPAllocationMethod: publicIpAllocationMethod
            }
          }
        ]
      }
    ]
  }
}
var vm2PrivateIpAddress = vm2.outputs.nicConfigurations[0].?ipConfigurations[0].?privateIP

// Private DNS Zone
module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.0' = {
  name: '${appVNetPrivateDnsZoneName}-deployment'
  params: {
    name: appVNetPrivateDnsZoneName
    virtualNetworkLinks: [
      {
        name: '${appVnetName}-link'
        virtualNetworkResourceId: appVNetResourceId
        registrationEnabled: true
      }
    ]
    a: [
      {
        name: '${vm1Name}-a-record'
        ttl: 3600
        aRecords: [
          {
            ipv4Address: vm1PrivateIpAddress
          }
        ]
      }
      {
        name: '${vm2Name}-a-record'
        ttl: 3600
        aRecords: [
          {
            ipv4Address: vm2PrivateIpAddress
          }
        ]
      }
    ]
  }
}
