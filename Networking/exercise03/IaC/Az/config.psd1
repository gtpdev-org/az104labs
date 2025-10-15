
@{
    ResourceGroupName = 'RG1-AzurePowerShell'
    Location          = 'eastus'
    Networking        = @{
        PublicIpAddress = @{
            AllocationMethod = 'Static'
            SkuName          = 'Standard'
            SkuTier          = 'Regional'
            Version          = 'IPv4'
        }
        HubVNet         = @{
            Name           = 'hub-vnet'
            AddressPrefix  = '10.0.0.0/16'
            FirewallSubnet = @{
                Name          = 'AzureFirewallSubnet'
                AddressPrefix = '10.0.0.0/26'
            }
        }
        AppVNet         = @{
            Name           = 'app-vnet'
            AddressPrefix  = '10.1.0.0/16'
            FrontendSubnet = @{
                Name          = 'frontend'
                AddressPrefix = '10.1.0.0/24'
            }
            BackendSubnet  = @{
                Name          = 'backend'
                AddressPrefix = '10.1.1.0/24'
            }
            FirewallSubnet = @{
                Name          = 'AzureFirewallSubnet'
                AddressPrefix = '10.1.63.0/26'
            }
            Firewall       = @{
                Name                    = 'app-fw'
                PolicyName              = 'app-fw-policy'
                PolicySkuTier           = 'Standard'
                PublicIpName            = 'app-fw-pip'
                SkuName                 = 'AZFW_VNet'
                SkuTier                 = 'Standard'
                AllowDnsRule            = @{
                    Name                 = 'AllowDns'
                    RuleType             = 'NetworkRule'
                    SourceAddresses      = @('10.1.0.0/23')
                    DestinationAddresses = @('1.1.1.1', '1.0.0.1')
                    DestinationPorts     = @('53')
                    IpProtocols          = @('UDP', 'TCP')
                }
                AllowAzurePipelinesRule = @{
                    Name            = 'AllowAzurePipelines'
                    RuleType        = 'ApplicationRule'
                    Protocols       = @(@{ protocolType = 'Https'; port = 443 })
                    TargetFqdns     = @('dev.azure.com', 'azure.microsoft.com')
                    TerminateTLS    = $false
                    SourceAddresses = @('10.1.0.0/23')
                }
            }

        }
        Peerings        = @{
            HubToApp = 'hub-to-app-vnet'
            AppToHub = 'app-vnet-to-hub'
        }
        ASG             = @{
            Name = 'app-frontend-asg'
        }
        NSG             = @{
            Name            = 'app-vnet-nsg'
            NsgRuleAllowSsh = @{
                Name                 = 'AllowSSH'
                Protocol             = 'Tcp'
                SourcePortRange      = '*'
                DestinationPortRange = '22'
                SourceAddressPrefix  = '*'
                Access               = 'Allow'
                Priority             = 100
                Direction            = 'Inbound'
            }
        }
    }
    VirtualMachines   = @{
        Size  = 'Standard_D2s_v6'
        Image = @{
            Publisher = 'canonical'
            Offer     = 'ubuntu-24_04-lts'
            Sku       = 'minimal'
            Version   = 'latest'
        }
        Disk  = @{
            OsType             = 'Linux'
            SizeGB             = 30
            Caching            = 'ReadWrite'
            CreateOption       = 'FromImage'
            StorageAccountType = 'Standard_LRS'
            DeleteOption       = 'Delete'
        }
        VM1   = @{
            Name     = 'VM1'
            VNetName = 'app-vnet'
            NIC      = @{
                Name = 'VM1-nic'
            }
            PublicIp = @{
                Name = 'VM1-ip'
            }
        }
        VM2   = @{
            Name     = 'VM2'
            VNetName = 'app-vnet'
            NIC      = @{
                Name = 'VM2-nic'
            }
            PublicIp = @{
                Name = 'VM2-ip'
            }
        }
    }
}
