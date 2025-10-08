# --------------------------------
# Azure Resource Deployment Script
# --------------------------------

Write-Host "=== Azure Resource Deployment Script ===" -ForegroundColor Cyan


# -------------------------------
# Load configuration
# -------------------------------

# Path to the configuration file
$configPath = "$PSScriptRoot\config.psd1"
Write-Host "Loading configuration from $configPath" -ForegroundColor Cyan

# Check if the configuration file exists, exit if not
if (-not (Test-Path $configPath)) {
    Write-Host "Configuration file not found: $configPath" -ForegroundColor Red
    exit
}

# Load the configuration
$config = Import-PowerShellDataFile -Path $configPath

Write-Host "Configuration loaded successfully." -ForegroundColor Green
Write-Host "Loaded configuration values:" -ForegroundColor Green

function Write-ConfigValues {
    param (
        [Parameter(Mandatory)]
        [object]$Config,
        [string]$Indent = ""
    )
    foreach ($item in $Config.GetEnumerator()) {
        if ($item.Value -is [System.Collections.IDictionary]) {
            Write-Host "$Indent$($item.Key):"
            Write-ConfigValues -Config $item.Value -Indent ("$Indent  ")
        }
        elseif ($item.Value -is [System.Collections.IEnumerable] -and
            -not ($item.Value -is [string])) {
            Write-Host "$Indent$($item.Key):"
            $i = 0
            foreach ($v in $item.Value) {
                if ($v -is [System.Collections.IDictionary]) {
                    Write-Host "$Indent  [$i]:"
                    Write-ConfigValues -Config $v -Indent ("$Indent    ")
                }
                else {
                    Write-Host "$Indent  [$i]: $v"
                }
                $i++
            }
        }
        else {
            Write-Host "$Indent$($item.Key): $($item.Value)"
        }
    }
}
Write-ConfigValues -Config $config


# ---------------------------------------
# Capture Admin Credentials for VMs
# ---------------------------------------
$vmCredentials = Get-Credential -Message "Enter the VM admin credentials"

Write-Host "VM Admin User: $($vmCredentials.UserName)" -ForegroundColor Green
Write-Host "VM Admin Password: $($vmCredentials.GetNetworkCredential().Password)" -ForegroundColor Green


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


# Explicitly set the subscription context to avoid context loss
Set-AzContext -SubscriptionId $subscription.Id


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
    Name        = $config.ResourceGroupName
    Location    = $config.Location
    ErrorAction = 'SilentlyContinue'
}
$resourceGroup = New-AzResourceGroup @resourceGroupConfig

$resourceGroup = Get-AzResourceGroup -Name $config.ResourceGroupName

# Validate the result
if (-not $resourceGroup) {
    Write-Host "Failed to create Resource Group '$($config.ResourceGroupName)'. Please check your parameters and Azure permissions." -ForegroundColor Red
    exit
}
else {
    Write-Host "Resource Group '$($resourceGroup.ResourceGroupName)' created successfully with Id '$($resourceGroup.ResourceId)'" -ForegroundColor Green
}


# -------------------------------
# Create Hub VNet
# -------------------------------

# Create Hub VNet
$hubVNetConfig = @{
    Name              = $config.Networking.HubVNet.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
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

# Obtain a fresh reference to the Hub VNet
$hubVNet = Get-AzVirtualNetwork -Name $hubVNet.Name -ResourceGroupName $resourceGroup.ResourceGroupName

# Validate creation
if (-not $hubVNet) {
    Write-Host "Failed to create Virtual Network '$($config.Networking.HubVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Virtual Network '$($hubVNet.Name)' created successfully in '$($hubVNet.Location)' with Id '$($hubVNet.Id)'" -ForegroundColor Green
}



# -------------------------------
# Create App VNet
# -------------------------------

# Create App VNet
$appVNetConfig = @{
    Name              = $config.Networking.AppVNet.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
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

# Obtain a fresh reference to the App VNet
$appVNet = Get-AzVirtualNetwork -Name $appVNet.Name -ResourceGroupName $resourceGroup.ResourceGroupName

# Validate creation
if (-not $appVNet) {
    Write-Host "Failed to create Virtual Network '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Virtual Network '$($appVNet.Name)' created successfully in '$($appVNet.Location)' with Id '$($appVNet.Id)'" -ForegroundColor Green
}

# Get a reference to the frontend subnet
$frontendSubnet = $appVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.AppVNet.FrontendSubnet.Name }
if (-not $frontendSubnet) {
    Write-Host "Subnet '$($config.Networking.AppVNet.FrontendSubnet.Name)' not found in VNet '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to frontend subnet '$($frontendSubnet.Name)' (Id = $($frontendSubnet.Id)) obtained successfully." -ForegroundColor Green
}

# Get a reference to the backend subnet
$backendSubnet = $appVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.AppVNet.BackendSubnet.Name }
if (-not $backendSubnet) {
    Write-Host "Subnet '$($config.Networking.AppVNet.BackendSubnet.Name)' not found in VNet '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to backend subnet '$($backendSubnet.Name)' (Id = $($backendSubnet.Id)) obtained successfully." -ForegroundColor Green
}



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
# Create Public IP for VM1
# -------------------------------
$vm1PublicIPConfig = @{
    Name              = $config.VirtualMachines.VM1.PublicIP.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $config.Location
    AllocationMethod  = 'Static'
}
$vm1PublicIP = New-AzPublicIpAddress @vm1PublicIPConfig

# Validate creation
if (-not $vm1PublicIP) {
    Write-Host "Failed to create Public IP '$($config.VirtualMachines.VM1.PublicIP.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Public IP '$($vm1PublicIP.Name)' created successfully at '$($vm1PublicIP.IpAddress)' with Id '$($vm1PublicIP.Id)'." -ForegroundColor Green
}



# -------------------------------
# Create Public IP for VM2
# -------------------------------
$vm2PublicIPConfig = @{
    Name              = $config.VirtualMachines.VM2.PublicIP.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $config.Location
    AllocationMethod  = 'Static'
}
$vm2PublicIP = New-AzPublicIpAddress @vm2PublicIPConfig

# Validate creation
if (-not $vm2PublicIP) {
    Write-Host "Failed to create Public IP '$($config.VirtualMachines.VM2.PublicIP.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Public IP '$($vm2PublicIP.Name)' created successfully at '$($vm2PublicIP.IpAddress)' with Id '$($vm2PublicIP.Id)'." -ForegroundColor Green
}


# ------------------------------------------------------
# Create Application Security Group for Frontend Subnet
# ------------------------------------------------------

# Create ASG
$appASGConfig = @{
    Name              = $config.Networking.ASG.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $config.Location
}
$appASG = New-AzApplicationSecurityGroup @appASGConfig

# Validate creation
if (-not $appASG) {
    Write-Host "Failed to create Application Security Group '$($config.Networking.ASG.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Application Security Group '$($appASG.Name)' created successfully with Id '$($appASG.Id)'." -ForegroundColor Green
}


# -------------------------------
# Create NIC for VM1
# -------------------------------

# Create NIC for VM1
$vm1NicConfig = @{
    Name                       = $config.VirtualMachines.VM1.NIC.Name
    ResourceGroupName          = $resourceGroup.ResourceGroupName
    Location                   = $config.Location
    SubnetId                   = $frontendSubnet.Id
    PublicIpAddressId          = $vm1PublicIP.Id
    ApplicationSecurityGroupId = $appASG.Id

}
$vm1Nic = New-AzNetworkInterface @vm1NicConfig

# Validate creation
if (-not $vm1Nic) {
    Write-Host "Failed to create NIC '$($config.VirtualMachines.VM1.NIC.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NIC '$($vm1Nic.Name)' created successfully with Id '$($vm1Nic.Id)'." -ForegroundColor Green
}


# ----------------------------------------
# Create Network Security Group and Rules
# ----------------------------------------

# Create NSG
$nsgConfig = @{
    Name              = $config.Networking.NSG.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $config.Location
}
$nsg = New-AzNetworkSecurityGroup @nsgConfig

# Validate creation
if (-not $nsg) {
    Write-Host "Failed to create Network Security Group '$($config.Networking.NSG.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Network Security Group '$($nsg.Name)' created successfully with Id '$($nsg.Id)'." -ForegroundColor Green
}

#  Create NSG Rule to allow SSH from Internet
$nsgRuleConfig = @{
    Name                                  = 'AllowSSH'
    NetworkSecurityGroup                  = $nsg
    Priority                              = 100
    SourceAddressPrefix                   = '*'
    SourcePortRange                       = '*'
    Direction                             = 'Inbound'
    DestinationApplicationSecurityGroupId = $appASG.Id
    DestinationPortRange                  = '22'
    Access                                = 'Allow'
    Protocol                              = 'Tcp'
}
$nsg = Add-AzNetworkSecurityRuleConfig @nsgRuleConfig
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

$nsg = Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $resourceGroup.ResourceGroupName
$nsgRule = Get-AzNetworkSecurityRuleConfig -Name $nsgRuleConfig.Name -NetworkSecurityGroup $nsg

# Validate creation
if (-not $nsgRule) {
    Write-Host "Failed to create NSG Rule 'AllowSSH'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NSG Rule '$($nsgRule.Name)' created successfully with Id '$($nsgRule.Id)'." -ForegroundColor Green
}

# Validate NSG update
if (-not $nsg) {
    Write-Host "Failed to update Network Security Group '$($config.Networking.NSG.Name)' with new rules." -ForegroundColor Red
    exit
}
else {
    Write-Host "Network Security Group '$($nsg.Name)' updated successfully with new rules:" -ForegroundColor Green
    $nsg.SecurityRules | Select-Object Name, Priority, Access, Direction, DestinationPortRange, SourceAddressPrefix, DestinationAddressPrefix, Protocol | Format-Table -AutoSize
}


# -------------------------------
# Create NIC for VM2
# -------------------------------

# Create NIC for VM2
$vm2NicConfig = @{
    Name                   = $config.VirtualMachines.VM2.NIC.Name
    ResourceGroupName      = $resourceGroup.ResourceGroupName
    Location               = $config.Location
    SubnetId               = $backendSubnet.Id
    PublicIpAddressId      = $vm2PublicIP.Id
    NetworkSecurityGroupId = $nsg.Id
}
$vm2Nic = New-AzNetworkInterface @vm2NicConfig

# Validate creation
if (-not $vm2Nic) {
    Write-Host "Failed to create NIC '$($config.VirtualMachines.VM2.NIC.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NIC '$($vm2Nic.Name)' created successfully with Id '$($vm2Nic.Id)'." -ForegroundColor Green
}


# ------------------------
# Create Virtual Machines
# ------------------------

# Create VM1

$vm1BaseConfig = @{
    VMName = $config.VirtualMachines.VM1.Name # e.g., 'VM1'
    VMSize = $config.VirtualMachines.Size     # e.g., 'Standard_D2s_v6'
}
$vm1 = New-AzVMConfig @vm1BaseConfig

$vm1ImageConfig = @{
    VM            = $vm1
    PublisherName = $config.VirtualMachines.Image.Publisher # e.g., 'canonical'
    Offer         = $config.VirtualMachines.Image.Offer     # e.g., 'ubuntu-24_04-lts'
    Skus          = $config.VirtualMachines.Image.Sku       # e.g., 'minimal'
    Version       = $config.VirtualMachines.Image.Version   # e.g., 'latest'
}
$vm1 = Set-AzVMSourceImage @vm1ImageConfig

$vm1OsDiskConfig = @{
    VM                 = $vm1 
    Name               = "$($config.VirtualMachines.VM1.Name)-osdisk"
    CreateOption       = $config.VirtualMachines.Disk.CreateOption       # e.g., 'FromImage'
    DiskSizeInGB       = $config.VirtualMachines.Disk.SizeGB             # e.g., 30
    StorageAccountType = $config.VirtualMachines.Disk.StorageAccountType # e.g., 'Standard_LRS'
    Caching            = $config.VirtualMachines.Disk.Caching            # e.g., 'ReadWrite'
}
$vm1 = Set-AzVMOSDisk @vm1OsDiskConfig

$vm1OsConfig = @{
    VM           = $vm1
    Linux        = $true
    ComputerName = $config.VirtualMachines.VM1.Name
    Credential   = $vmCredentials
}
$vm1 = Set-AzVMOperatingSystem @vm1OsConfig

$vm1NicConfig = @{
    VM = $vm1
    Id = $vm1Nic.Id
}
$vm1 = Add-AzVMNetworkInterface @vm1NicConfig

$vm1DeploymentConfig = @{
    ResourceGroupName = $resourceGroup.ResourceGroupName # e.g., 'RG1'
    Location          = $config.Location                 # e.g., 'eastus'
    VM                = $vm1
}
$vm1DeploymentResult = New-AzVM @vm1DeploymentConfig

# Validate deployment result
if (-not $vm1DeploymentResult) {
    Write-Host "Failed to deploy Virtual Machine '$($config.VirtualMachines.VM1.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Deployment of Virtual Machine '$($config.VirtualMachines.VM1.Name)' initiated successfully with status code $($vm1DeploymentResult.StatusCode)." -ForegroundColor Green
}


# Create VM2

$vm2BaseConfig = @{
    VMName = $config.VirtualMachines.VM2.Name # e.g., 'VM2'
    VMSize = $config.VirtualMachines.Size     # e.g., 'Standard_D2s_v6'
}
$vm2 = New-AzVMConfig @vm2BaseConfig

$vm2ImageConfig = @{
    VM            = $vm2
    PublisherName = $config.VirtualMachines.Image.Publisher # e.g., 'canonical'
    Offer         = $config.VirtualMachines.Image.Offer     # e.g., 'ubuntu-24_04-lts'
    Skus          = $config.VirtualMachines.Image.Sku       # e.g., 'minimal'
    Version       = $config.VirtualMachines.Image.Version   # e.g., 'latest'
}
$vm2 = Set-AzVMSourceImage @vm2ImageConfig

$vm2OsDiskConfig = @{
    VM                 = $vm2
    Name               = "$($config.VirtualMachines.VM2.Name)-osdisk"
    CreateOption       = $config.VirtualMachines.Disk.CreateOption       # e.g., 'FromImage'
    DiskSizeInGB       = $config.VirtualMachines.Disk.SizeGB             # e.g., 30
    StorageAccountType = $config.VirtualMachines.Disk.StorageAccountType # e.g., 'Standard_LRS'
    Caching            = $config.VirtualMachines.Disk.Caching            # e.g., 'ReadWrite'
}
$vm2 = Set-AzVMOSDisk @vm2OsDiskConfig

$vm2OsConfig = @{
    VM           = $vm2
    Linux        = $true
    ComputerName = $config.VirtualMachines.VM2.Name
    Credential   = $vmCredentials
}
$vm2 = Set-AzVMOperatingSystem @vm2OsConfig

$vm2NicConfig = @{
    VM = $vm2
    Id = $vm2Nic.Id
}
$vm2 = Add-AzVMNetworkInterface @vm2NicConfig

$vm2DeploymentConfig = @{
    ResourceGroupName = $resourceGroup.ResourceGroupName # e.g., 'RG1'
    Location          = $config.Location                 # e.g., 'eastus'
    VM                = $vm2
}
$vm2DeploymentResult = New-AzVM @vm2DeploymentConfig

# Validate deployment result
if (-not $vm2DeploymentResult) {
    Write-Host "Failed to deploy Virtual Machine '$($config.VirtualMachines.VM2.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Deployment of Virtual Machine '$($config.VirtualMachines.VM2.Name)' initiated successfully with status code $($vm2DeploymentResult.StatusCode)." -ForegroundColor Green
}


# -------------------------------
# Completion Message
# -------------------------------

Write-Host "`nDeployment completed successfully!" -ForegroundColor Cyan
