
@{
    ResourceGroupName = 'RG1-AzurePowerShell'
    Location          = 'eastus'
    Networking        = @{
        HubVNet  = @{
            Name           = 'hub-vnet'
            AddressPrefix  = '10.0.0.0/16'
            FirewallSubnet = @{
                Name          = 'AzureFirewallSubnet'
                AddressPrefix = '10.0.0.0/26'
            }
        }
        AppVNet  = @{
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
        }
        Peerings = @{
            HubToApp = 'hub-to-app-vnet'
            AppToHub = 'app-vnet-to-hub'
        }
        ASG      = @{
            Name = 'app-frontend-asg'
        }
        NSG      = @{
            Name = 'app-vnet-nsg'
        }
    }
    VirtualMachines   = @{
        Size         = 'Standard_D2s_v6'
        Image           = @{
            Publisher = 'canonical'
            Offer     = 'ubuntu-24_04-lts'
            Sku       = 'minimal'
            Version   = 'latest'
        }
        Disk         = @{
            OsType             = 'Linux'
            SizeGB             = 30
            Caching            = 'ReadWrite'
            CreateOption       = 'FromImage'
            StorageAccountType = 'Standard_LRS'
        }
        VM1          = @{
            Name     = 'VM1'
            VNetName = 'app-vnet'
            NIC      = @{
                Name = 'VM1-nic'
            }
            PublicIp = @{
                Name = 'VM1-ip'
            }
        }
        VM2          = @{
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
