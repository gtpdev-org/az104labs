# --------------------------------
# Azure Resource Deployment Script
# --------------------------------

Write-Host "=== Azure Resource Deployment Script ===" -ForegroundColor Cyan

# -------------------------------
# Load configuration
# -------------------------------

# Path to the configuration file
$configPath = ".\config.psd1"

# Check if the configuration file exists, exit if not
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit
}

# Load the configuration
$config = Import-PowerShellDataFile -Path $configPath
Write-Host "Configuration loaded successfully." -ForegroundColor Green


# ---------------------------------------
# Login to Azure and select Subscription
# ---------------------------------------
Write-Host "Logging in to Azure..." -ForegroundColor Yellow

# Use device authentication for login
$account = Connect-AzAccount -UseDeviceAuthentication -ErrorAction SilentlyContinue

# Validate login, exit if failed
if (-not $account) {
    Write-Host "Login failed. Please check your credentials or network connection." -ForegroundColor Red
    exit
}

# Get the current context
$currentContext = Get-AzContext

# Ensure the context was set, exit if not
if (-not $currentContext.Account) {
    Write-Host "No Azure context found after login. Exiting." -ForegroundColor Red
    exit
}

# Obtain a reference to the Subscription
$subscription = $currentContext.Subscription

Write-Host "Login successful.`nAccount: $($currentContext.Account)`nSubscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Green


# -------------------------------
# Resource Group Creation
# -------------------------------

# Attempt to retrieve the Resource Group
$existingRG = Get-AzResourceGroup -Name $config.ResourceGroupName -ErrorAction SilentlyContinue

# Check if the Resource Group already exists
# Remove it if in the same location, else exit
if ($existingRG) {
    Write-Host "`nResource Group '$($existingRG.ResourceGroupName)' already exists in location '$($existingRG.Location)'." -ForegroundColor Red
    if ($existingRG.Location -eq $config.Location) {
        Write-Host "Deleting existing Resource Group..." -ForegroundColor Red
        Remove-AzResourceGroup -Name $config.ResourceGroupName -Force -Confirm:$false
        Write-Host "Resource Group '$($config.ResourceGroupName)' deleted successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Please choose a different name or delete the existing Resource Group before proceeding." -ForegroundColor Yellow
        exit
    }
}

# Create the Resource Group
Write-Host "`nCreating Resource Group '$($config.ResourceGroupName)' in '$($config.Location)'..." -ForegroundColor Yellow
$resourceGroupConfig = @{
    Name              = $config.ResourceGroupName
    Location          = $config.Location
    ErrorAction       = 'SilentlyContinue'
}
$resourceGroup = New-AzResourceGroup @resourceGroupConfig

# Validate the result
if (-not $resourceGroup) {
    Write-Host "Failed to create Resource Group '$($config.ResourceGroupName)'. Please check your parameters and Azure permissions." -ForegroundColor Red
    exit
}
else {
    Write-Host "Resource Group created successfully!" -ForegroundColor Green
}


# -------------------------------
# Create Hub VNet
# -------------------------------

# Create Hub VNet
$hubVNetConfig = @{
    Name              = $config.Networking.HubVNet.Name
    ResourceGroupName = $config.ResourceGroupName
    Location          = $config.Location
    AddressPrefix     = $config.Networking.HubVNet.AddressPrefix
}
$hubVNet = New-AzVirtualNetwork @hubVNetConfig

# Create Firewall Subnet
$firewallSubnetConfig = @{
    Name           = $config.Networking.HubVNet.FirewallSubnet.Name
    VirtualNetwork = $hubVNet
    AddressPrefix  = $config.Networking.HubVNet.FirewallSubnet.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @firewallSubnetConfig

# Finalize VNet creation
$hubVNet | Set-AzVirtualNetwork

# Validate creation
if (-not $hubVNet) {
    Write-Host "Failed to create Virtual Network '$($config.Networking.HubVNet.Name)'." -ForegroundColor Red
    exit
}

Write-Host "Virtual Network '$($hubVNet.Name)' created successfully in '$($hubVNet.Location)'." -ForegroundColor Green


# -------------------------------
# Create App VNet
# -------------------------------

# Create App VNet
$appVNetConfig = @{
    Name              = $config.Networking.AppVNet.Name
    ResourceGroupName = $config.ResourceGroupName
    Location          = $config.Location
    AddressPrefix     = $config.Networking.AppVNet.AddressPrefix
}
$appVNet = New-AzVirtualNetwork @appVNetConfig

# Create Frontend Subnet
$frontendSubnetConfig = @{
    Name           = $config.Networking.AppVNet.FrontendSubnet.Name
    VirtualNetwork = $appVNet
    AddressPrefix  = $config.Networking.AppVNet.FrontendSubnet.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @frontendSubnetConfig

# Create Backend Subnet
$backendSubnetConfig = @{
    Name           = $config.Networking.AppVNet.BackendSubnet.Name
    VirtualNetwork = $appVNet
    AddressPrefix  = $config.Networking.AppVNet.BackendSubnet.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @backendSubnetConfig

# Finalize VNet creation
$appVNet | Set-AzVirtualNetwork

# Validate creation
if (-not $appVNet) {
    Write-Host "Failed to create Virtual Network '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}

Write-Host "Virtual Network '$($appVNet.Name)' created successfully in '$($appVNet.Location)'." -ForegroundColor Green


# -------------------------------
# Create VNet Peerings
# -------------------------------

# Create Hub-to-App VNet Peering
$hubToAppPeeringConfig = @{
    Name                   = $config.Networking.Peerings.HubToApp
    VirtualNetwork         = $hubVNet
    RemoteVirtualNetworkId = $appVNet.Id
    AllowForwardedTraffic  = $true
}
$hubToAppPeering = Add-AzVirtualNetworkPeering @hubToAppPeeringConfig

# Validate creation
if (-not $hubToAppPeering) {
    Write-Host "Failed to create VNet peering '$($config.Networking.Peerings.HubToApp)'." -ForegroundColor Red
    exit
}

# Create App-to-Hub VNet Peering
$appToHubPeeringConfig = @{
    Name                   = $config.Networking.Peerings.AppToHub
    VirtualNetwork         = $appVNet
    RemoteVirtualNetworkId = $hubVNet.Id
    AllowForwardedTraffic  = $true
}
$appToHubPeering = Add-AzVirtualNetworkPeering @appToHubPeeringConfig

# Validate creation
if (-not $appToHubPeering) {
    Write-Host "Failed to create VNet peering '$($config.Networking.Peerings.AppToHub)'." -ForegroundColor Red
    exit
}

Write-Host "Virtual Network Peerings created successfully!." -ForegroundColor Green


# -------------------------------
# Completion Message
# -------------------------------

Write-Host "`nDeployment completed successfully!" -ForegroundColor Cyan
