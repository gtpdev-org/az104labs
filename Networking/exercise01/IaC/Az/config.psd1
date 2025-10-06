
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
    }
}
