
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
            Name          = 'hub-vnet'
            AddressPrefix = '10.0.0.0/16'
            Subnet        = @{
                Firewall = @{
                    Name          = 'AzureFirewallSubnet'
                    AddressPrefix = '10.0.0.0/26'
                }
            }
        }
        AppVNet         = @{
            Name           = 'app-vnet'
            AddressPrefix  = '10.1.0.0/16'
            Subnet         = @{
                Frontend = @{
                    Name          = 'frontend'
                    AddressPrefix = '10.1.0.0/24'
                }
                Backend  = @{
                    Name          = 'backend'
                    AddressPrefix = '10.1.1.0/24'
                }
                Firewall = @{
                    Name          = 'AzureFirewallSubnet'
                    AddressPrefix = '10.1.63.0/26'
                }
            }
            Firewall       = @{
                Name         = 'app-vnet-fw'
                PublicIpName = 'app-vnet-fw-pip'
                Sku = @{
                    Name = 'AZFW_VNet'
                    Tier = 'Standard'
                }
                Policy       = @{
                    Name                 = 'app-vnet-fw-policy'
                    SkuTier                 = 'Standard'
                    RuleCollectionGroups = @{
                        Network     = @{
                            Name           = 'DefaultNetworkRuleCollectionGroup'
                            Priority       = 200
                            RuleCollection = @{
                                Name     = 'app-vnet-fw-policy-nrc'
                                Priority = 200
                                Action   = 'Allow'
                                AllowDns = @{
                                    Name                 = 'AllowDns'
                                    RuleType             = 'NetworkRule'
                                    SourceAddresses      = @('10.1.0.0/23')
                                    DestinationAddresses = @('1.1.1.1', '1.0.0.1')
                                    DestinationPorts     = @('53')
                                    IpProtocols          = @('UDP', 'TCP')
                                }
                            }
                        }
                        Application = @{
                            Name           = 'DefaultApplicationRuleCollectionGroup'
                            Priority       = 200
                            RuleCollection = @{
                                Name                = 'app-vnet-fw-policy-arc'
                                Priority            = 200
                                Action              = 'Allow'
                                AllowAzurePipelines = @{
                                    Name            = 'AllowAzurePipelines'
                                    RuleType        = 'ApplicationRule'
                                    Protocols       = @('https:443')
                                    TargetFqdns     = @('dev.azure.com', 'azure.microsoft.com')
                                    TerminateTLS    = $false
                                    SourceAddresses = @('10.1.0.0/23')
                                }
                            }
                        }
                    }
                }
            }
            SecurityGroups = @{
                Application = @{
                    Name = 'app-vnet-asg'
                }
                Network = @{
                    Name  = 'app-vnet-nsg'
                    Rules = @{
                        AllowSsh = @{
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
            }
        }
        Peerings        = @{
            HubToApp              = 'hub-to-app-vnet'
            AppToHub              = 'app-vnet-to-hub'
            AllowForwardedTraffic = $true
        }
    }
    VirtualMachines   = @{
        Size  = 'Standard_D2s_v5'
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
            Name         = 'VM1'
            VNetName     = 'app-vnet'
            NICName      = 'VM1-nic'
            PublicIpName = 'VM1-ip'
        }
        VM2   = @{
            Name         = 'VM2'
            VNetName     = 'app-vnet'
            NICName      = 'VM2-nic'
            PublicIpName = 'VM2-ip'
        }
    }
}
