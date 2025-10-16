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
$resourceGroupParams = @{
    Name        = $config.ResourceGroupName
    Location    = $config.Location
    ErrorAction = 'SilentlyContinue'
}
$resourceGroup = New-AzResourceGroup @resourceGroupParams

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
$hubVNetParams = @{
    Name              = $config.Networking.HubVNet.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $config.Location
    AddressPrefix     = $config.Networking.HubVNet.AddressPrefix
}
$hubVNet = New-AzVirtualNetwork @hubVNetParams

# Create Firewall Subnet
$hubVNetSubnetFirewallParams = @{
    VirtualNetwork = $hubVNet
    Name           = $config.Networking.HubVNet.Subnet.Firewall.Name
    AddressPrefix  = $config.Networking.HubVNet.Subnet.Firewall.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @hubVNetSubnetFirewallParams

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

# Get a reference to the firewall subnet
$hubVNetSubnetFirewall = $hubVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.HubVNet.Subnet.Firewall.Name }
if (-not $hubVNetSubnetFirewall) {
    Write-Host "Subnet '$($config.Networking.HubVNet.Subnet.Firewall.Name)' not found in VNet '$($config.Networking.HubVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to firewall subnet '$($hubVNetSubnetFirewall.Name)' (Id = $($hubVNetSubnetFirewall.Id)) obtained successfully." -ForegroundColor Green
}



# -------------------------------
# Create App VNet
# -------------------------------

# Create App VNet
$appVNetParams = @{
    Name              = $config.Networking.AppVNet.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    AddressPrefix     = $config.Networking.AppVNet.AddressPrefix
}
$appVNet = New-AzVirtualNetwork @appVNetParams

# Create Frontend Subnet
$appVNetSubnetFrontendParams = @{
    Name           = $config.Networking.AppVNet.Subnet.Frontend.Name
    VirtualNetwork = $appVNet
    AddressPrefix  = $config.Networking.AppVNet.Subnet.Frontend.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @appVNetSubnetFrontendParams

# Create Backend Subnet
$appVNetSubnetBackendParams = @{
    Name           = $config.Networking.AppVNet.Subnet.Backend.Name
    VirtualNetwork = $appVNet
    AddressPrefix  = $config.Networking.AppVNet.Subnet.Backend.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @appVNetSubnetBackendParams

# Create Firewall Subnet
$appVNetSubnetFirewallParams = @{
    Name           = $config.Networking.AppVNet.Subnet.Firewall.Name
    VirtualNetwork = $appVNet
    AddressPrefix  = $config.Networking.AppVNet.Subnet.Firewall.AddressPrefix
}
Add-AzVirtualNetworkSubnetConfig @appVNetSubnetFirewallParams

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
$appVNetSubnetFrontend = $appVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.AppVNet.Subnet.Frontend.Name }
if (-not $appVNetSubnetFrontend) {
    Write-Host "Subnet '$($config.Networking.AppVNet.Subnet.Frontend.Name)' not found in VNet '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to frontend subnet '$($appVNetSubnetFrontend.Name)' (Id = $($appVNetSubnetFrontend.Id)) obtained successfully." -ForegroundColor Green
}

# Get a reference to the backend subnet
$appVNetSubnetBackend = $appVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.AppVNet.Subnet.Backend.Name }
if (-not $appVNetSubnetBackend) {
    Write-Host "Subnet '$($config.Networking.AppVNet.Subnet.Backend.Name)' not found in VNet '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to backend subnet '$($appVNetSubnetBackend.Name)' (Id = $($appVNetSubnetBackend.Id)) obtained successfully." -ForegroundColor Green
}

# Get a reference to the firewall subnet
$appVNetSubnetFirewall = $appVNet.Subnets | Where-Object { $_.Name -eq $config.Networking.AppVNet.Subnet.Firewall.Name }
if (-not $appVNetSubnetFirewall) {
    Write-Host "Subnet '$($config.Networking.AppVNet.Subnet.Firewall.Name)' not found in VNet '$($config.Networking.AppVNet.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Reference to firewall subnet '$($appVNetSubnetFirewall.Name)' (Id = $($appVNetSubnetFirewall.Id)) obtained successfully." -ForegroundColor Green
}


# -------------------------------
# Create VNet Peerings
# -------------------------------

# Create Hub-to-App VNet Peering
$hubToAppPeeringParams = @{
    Name                   = $config.Networking.Peerings.HubToApp
    VirtualNetwork         = $hubVNet
    RemoteVirtualNetworkId = $appVNet.Id
    AllowForwardedTraffic  = $config.Networking.Peerings.AllowForwardedTraffic
}
$hubToAppPeering = Add-AzVirtualNetworkPeering @hubToAppPeeringParams

# Validate creation
if (-not $hubToAppPeering) {
    Write-Host "Failed to create VNet peering '$($config.Networking.Peerings.HubToApp)'." -ForegroundColor Red
    exit
}

# Create App-to-Hub VNet Peering
$appToHubPeeringParams = @{
    Name                   = $config.Networking.Peerings.AppToHub
    VirtualNetwork         = $appVNet
    RemoteVirtualNetworkId = $hubVNet.Id
    AllowForwardedTraffic  = $config.Networking.Peerings.AllowForwardedTraffic
}
$appToHubPeering = Add-AzVirtualNetworkPeering @appToHubPeeringParams

# Validate creation
if (-not $appToHubPeering) {
    Write-Host "Failed to create VNet peering '$($config.Networking.Peerings.AppToHub)'." -ForegroundColor Red
    exit
}

Write-Host "Virtual Network Peerings created successfully!." -ForegroundColor Green


# -------------------------------
# Create Public IPs
# -------------------------------

# Create Public IP for VM1
$vm1PublicIPParams = @{
    Name              = $config.VirtualMachines.VM1.PublicIpName
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    AllocationMethod  = $config.Networking.PublicIpAddress.AllocationMethod # e.g., 'Static'
    Sku               = $config.Networking.PublicIpAddress.SkuName  # e.g., 'Standard'
    Tier              = $config.Networking.PublicIpAddress.SkuTier  # e.g., 'Regional'
    IpAddressVersion  = $config.Networking.PublicIpAddress.Version  # e.g., 'IPv4'
}
$vm1PublicIP = New-AzPublicIpAddress @vm1PublicIPParams

# Validate creation
if (-not $vm1PublicIP) {
    Write-Host "Failed to create Public IP '$($config.VirtualMachines.VM1.PublicIpName)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Public IP '$($vm1PublicIP.Name)' created successfully at '$($vm1PublicIP.IpAddress)' with Id '$($vm1PublicIP.Id)'." -ForegroundColor Green
}


# Create Public IP for VM2
$vm2PublicIPParams = @{
    Name              = $config.VirtualMachines.VM2.PublicIpName
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    AllocationMethod  = $config.Networking.PublicIpAddress.AllocationMethod # e.g., 'Static'
    Sku               = $config.Networking.PublicIpAddress.SkuName  # e.g., 'Standard'
    Tier              = $config.Networking.PublicIpAddress.SkuTier  # e.g., 'Regional'
    IpAddressVersion  = $config.Networking.PublicIpAddress.Version  # e.g., 'IPv4'
}
$vm2PublicIP = New-AzPublicIpAddress @vm2PublicIPParams

# Validate creation
if (-not $vm2PublicIP) {
    Write-Host "Failed to create Public IP '$($config.VirtualMachines.VM2.PublicIpName)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Public IP '$($vm2PublicIP.Name)' created successfully at '$($vm2PublicIP.IpAddress)' with Id '$($vm2PublicIP.Id)'." -ForegroundColor Green
}


# Create Public IP for AppVNet Firewall
$appVNetFirewallPublicIPParams = @{
    Name              = $config.Networking.AppVNet.Firewall.PublicIPName
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    AllocationMethod  = $config.Networking.PublicIpAddress.AllocationMethod # e.g., 'Static'
    Sku               = $config.Networking.PublicIpAddress.SkuName  # e.g., 'Standard'
    Tier              = $config.Networking.PublicIpAddress.SkuTier  # e.g., 'Regional'
    IpAddressVersion  = $config.Networking.PublicIpAddress.Version  # e.g., 'IPv4'
}
$appVNetFirewallPublicIP = New-AzPublicIpAddress @appVNetFirewallPublicIPParams

# Validate creation
if (-not $appVNetFirewallPublicIP) {
    Write-Host "Failed to create Public IP '$($config.Networking.AppVNet.Firewall.PublicIPName)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Public IP '$($appVNetFirewallPublicIP.Name)' created successfully at '$($appVNetFirewallPublicIP.IpAddress)' with Id '$($appVNetFirewallPublicIP.Id)'." -ForegroundColor Green
}


# ------------------------------------------------------
# Create Application Security Group for Frontend Subnet
# ------------------------------------------------------

# Create ASG
$appVNetApplicationSecurityGroupParams = @{
    Name              = $config.Networking.AppVNet.SecurityGroups.Application.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
}
$appVNetApplicationSecurityGroup = New-AzApplicationSecurityGroup @appVNetApplicationSecurityGroupParams

# Validate creation
if (-not $appVNetApplicationSecurityGroup) {
    Write-Host "Failed to create Application Security Group '$($config.Networking.AppVNet.SecurityGroups.Application.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Application Security Group '$($appVNetApplicationSecurityGroup.Name)' created successfully with Id '$($appVNetApplicationSecurityGroup.Id)'." -ForegroundColor Green
}


# ----------------------------------------
# Create Network Security Group and Rules
# ----------------------------------------

# Create NSG
$appVNetNetworkSecurityGroupParams = @{
    Name              = $config.Networking.AppVNet.SecurityGroups.Network.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
}
$appVNetNetworkSecurityGroup = New-AzNetworkSecurityGroup @appVNetNetworkSecurityGroupParams

# Validate creation
if (-not $appVNetNetworkSecurityGroup) {
    Write-Host "Failed to create Network Security Group '$($config.Networking.AppVNet.SecurityGroups.Network.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Network Security Group '$($appVNetNetworkSecurityGroup.Name)' created successfully with Id '$($appVNetNetworkSecurityGroup.Id)'." -ForegroundColor Green
}

#  Create NSG Rule to allow SSH from Internet
$appVNetNsgRuleAllowSshParams = @{
    Name                                  = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.Name
    NetworkSecurityGroup                  = $appVNetNetworkSecurityGroup
    Priority                              = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.Priority
    SourceAddressPrefix                   = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.SourceAddressPrefix
    SourcePortRange                       = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.SourcePortRange
    Direction                             = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.Direction
    DestinationApplicationSecurityGroupId = $appVNetApplicationSecurityGroup.Id
    DestinationPortRange                  = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.DestinationPortRange
    Access                                = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.Access
    Protocol                              = $config.Networking.AppVNet.SecurityGroups.Network.Rules.AllowSSH.Protocol
}
$appVNetNetworkSecurityGroup = Add-AzNetworkSecurityRuleConfig @appVNetNsgRuleAllowSshParams

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $appVNetNetworkSecurityGroup

$appVNetNetworkSecurityGroup = Get-AzNetworkSecurityGroup -Name $appVNetNetworkSecurityGroup.Name -ResourceGroupName $resourceGroup.ResourceGroupName
$appVNetNsgRuleAllowSsh = Get-AzNetworkSecurityRuleConfig -Name $appVNetNsgRuleAllowSshParams.Name -NetworkSecurityGroup $appVNetNetworkSecurityGroup

# Validate creation
if (-not $appVNetNsgRuleAllowSsh) {
    Write-Host "Failed to create NSG Rule 'AllowSSH'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NSG Rule '$($appVNetNsgRuleAllowSsh.Name)' created successfully with Id '$($appVNetNsgRuleAllowSsh.Id)'." -ForegroundColor Green
}

# Validate NSG update
if (-not $appVNetNetworkSecurityGroup) {
    Write-Host "Failed to update Network Security Group '$($config.Networking.AppVNet.SecurityGroups.Network.Name)' with new rules." -ForegroundColor Red
    exit
}
else {
    Write-Host "Network Security Group '$($appVNetNetworkSecurityGroup.Name)' updated successfully with new rules:" -ForegroundColor Green
    $appVNetNetworkSecurityGroup.SecurityRules | Select-Object Name, Priority, Access, Direction, DestinationPortRange, SourceAddressPrefix, DestinationAddressPrefix, Protocol | Format-Table -AutoSize
}


# -------------------------------
# Create NICs
# -------------------------------

# Create NIC for VM1
$vm1NicParams = @{
    Name                       = $config.VirtualMachines.VM1.NICName
    ResourceGroupName          = $resourceGroup.ResourceGroupName
    Location                   = $resourceGroup.Location
    SubnetId                   = $appVNetSubnetFrontend.Id
    PublicIpAddressId          = $vm1PublicIP.Id
    ApplicationSecurityGroupId = $appVNetApplicationSecurityGroup.Id
}
$vm1Nic = New-AzNetworkInterface @vm1NicParams

# Validate creation
if (-not $vm1Nic) {
    Write-Host "Failed to create NIC '$($config.VirtualMachines.VM1.NICName)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NIC '$($vm1Nic.Name)' created successfully with Id '$($vm1Nic.Id)'." -ForegroundColor Green
}


# Create NIC for VM2
$vm2NicParams = @{
    Name                   = $config.VirtualMachines.VM2.NICName
    ResourceGroupName      = $resourceGroup.ResourceGroupName
    Location               = $resourceGroup.Location
    SubnetId               = $appVNetSubnetBackend.Id
    PublicIpAddressId      = $vm2PublicIP.Id
    NetworkSecurityGroupId = $appVNetNetworkSecurityGroup.Id
}
$vm2Nic = New-AzNetworkInterface @vm2NicParams

# Validate creation
if (-not $vm2Nic) {
    Write-Host "Failed to create NIC '$($config.VirtualMachines.VM2.NICName)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "NIC '$($vm2Nic.Name)' created successfully with Id '$($vm2Nic.Id)'." -ForegroundColor Green
}


# ----------------------------------------
# Create Azure Firewall Policy in App VNet
# ----------------------------------------
$appVNetFirewallPolicyParams = @{
    Name              = $config.Networking.AppVNet.Firewall.Policy.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    SkuTier           = $config.Networking.AppVNet.Firewall.Policy.SkuTier
}
$appVNetFirewallPolicy = New-AzFirewallPolicy @appVNetFirewallPolicyParams

# Validate creation
if (-not $appVNetFirewallPolicy) {
    Write-Host "Failed to create Azure Firewall Policy '$($config.Networking.AppVNet.Firewall.Policy.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Policy '$($appVNetFirewallPolicy.Name)' created successfully with Id '$($appVNetFirewallPolicy.Id)'." -ForegroundColor Green
}


# ----------------------------------
# Create Azure Firewall Network Rule
# ----------------------------------
$appVNetFirewallPolicyNetworkRuleParams = @{
    Name               = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.Name
    SourceAddress      = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.SourceAddresses
    DestinationAddress = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.DestinationAddresses
    DestinationPort    = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.DestinationPorts
    Protocol           = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.IpProtocols
}
$appVNetFirewallPolicyNetworkRule = New-AzFirewallPolicyNetworkRule  @appVNetFirewallPolicyNetworkRuleParams

# Validate creation
if (-not $appVNetFirewallPolicyNetworkRule) {
    Write-Host "Failed to create Azure Firewall Network Rule '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.AllowDns.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Network Rule '$($appVNetFirewallPolicyNetworkRule.Name)' created successfully." -ForegroundColor Green
}


# --------------------------------
# Create Azure Firewall Network Filter Rule Collection
# --------------------------------
$appVNetFirewallPolicyNetworkFilterRuleCollectionParams = @{
    Name     = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.Name
    Priority = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.Priority
    Action   = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.Action
    Rule     = $appVNetFirewallPolicyNetworkRule
}
$appVNetFirewallPolicyFilterRuleCollection = New-AzFirewallPolicyFilterRuleCollection  @appVNetFirewallPolicyNetworkFilterRuleCollectionParams

# Validate creation
if (-not $appVNetFirewallPolicyFilterRuleCollection) {
    Write-Host "Failed to create Azure Firewall Network Filter Rule Collection '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.RuleCollection.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Network Filter Rule Collection '$($appVNetFirewallPolicyFilterRuleCollection.Name)' created successfully." -ForegroundColor Green
}


# --------------------------------
# Create Azure Firewall Network Rule Collection Group
# --------------------------------  
$appVNetFirewallPolicyNetworkRuleCollectionGroupParams = @{
    ResourceGroupName  = $resourceGroup.ResourceGroupName
    Name               = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.Name
    Priority           = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.Priority
    FirewallPolicyName = $appVNetFirewallPolicy.Name
    RuleCollection     = $appVNetFirewallPolicyFilterRuleCollection
}
New-AzFirewallPolicyRuleCollectionGroup  @appVNetFirewallPolicyNetworkRuleCollectionGroupParams

$appVNetFirewallPolicyNetworkRuleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.Name -AzureFirewallPolicy $appVNetFirewallPolicy

# Validate creation
if (-not $appVNetFirewallPolicyNetworkRuleCollectionGroup) {
    Write-Host "Failed to create Azure Firewall Network Rule Collection Group '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Network.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Network Rule Collection Group '$($appVNetFirewallPolicyNetworkRuleCollectionGroup.Name)' created successfully." -ForegroundColor Green
}


# ----------------------------------
# Create Azure Firewall Application Rule
# ----------------------------------
$appVNetFirewallPolicyApplicationRuleParams = @{
    Name          = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.Name
    TargetFqdn    = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.TargetFqdns
    Protocol      = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.Protocols
    SourceAddress = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.SourceAddresses
    TerminateTLS  = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.TerminateTLS
}
$appVNetFirewallPolicyApplicationRule = New-AzFirewallPolicyApplicationRule  @appVNetFirewallPolicyApplicationRuleParams

# Validate creation
if (-not $appVNetFirewallPolicyApplicationRule) {
    Write-Host "Failed to create Azure Firewall Application Rule '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.AllowAzurePipelines.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Application Rule '$($appVNetFirewallPolicyApplicationRule.Name)' created successfully." -ForegroundColor Green
}


# --------------------------------
# Create Azure Firewall Application Filter Rule Collection
# --------------------------------
$appVNetFirewallPolicyApplicationFilterRuleCollectionParams = @{
    Name     = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.Name
    Priority = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.Priority
    Action   = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.Action
    Rule     = $appVNetFirewallPolicyApplicationRule
}
$appVNetFirewallPolicyApplicationFilterRuleCollection = New-AzFirewallPolicyFilterRuleCollection  @appVNetFirewallPolicyApplicationFilterRuleCollectionParams

# Validate creation
if (-not $appVNetFirewallPolicyApplicationFilterRuleCollection) {
    Write-Host "Failed to create Azure Firewall Application Filter Rule Collection '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.RuleCollection.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Application Filter Rule Collection '$($appVNetFirewallPolicyApplicationFilterRuleCollection.Name)' created successfully." -ForegroundColor Green
}


# --------------------------------
# Create Azure Firewall Application Rule Collection Group
# --------------------------------  
$appVNetFirewallPolicyApplicationRuleCollectionGroupParams = @{
    ResourceGroupName  = $resourceGroup.ResourceGroupName
    Name               = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.Name
    Priority           = $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.Priority
    FirewallPolicyName = $appVNetFirewallPolicy.Name
    RuleCollection     = $appVNetFirewallPolicyApplicationFilterRuleCollection
}
New-AzFirewallPolicyRuleCollectionGroup  @appVNetFirewallPolicyApplicationRuleCollectionGroupParams

$appVNetFirewallPolicyApplicationRuleCollectionGroup = Get-AzFirewallPolicyRuleCollectionGroup -Name $config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.Name -AzureFirewallPolicy $appVNetFirewallPolicy

# Validate creation
if (-not $appVNetFirewallPolicyApplicationRuleCollectionGroup) {
    Write-Host "Failed to create Azure Firewall Application Rule Collection Group '$($config.Networking.AppVNet.Firewall.Policy.RuleCollectionGroups.Application.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall Application Rule Collection Group '$($appVNetFirewallPolicyApplicationRuleCollectionGroup.Name)' created successfully." -ForegroundColor Green
}


# --------------------------------
# Create Azure Firewall in App VNet 
# -------------------------------- 

#refresh firewall policy reference
$appVNetFirewallPolicy = Get-AzFirewallPolicy -Name $appVNetFirewallPolicy.Name -ResourceGroupName $resourceGroup.ResourceGroupName

$appVNetFirewallParams = @{
    Name              = $config.Networking.AppVNet.Firewall.Name
    ResourceGroupName = $resourceGroup.ResourceGroupName
    Location          = $resourceGroup.Location
    SkuName           = $config.Networking.AppVNet.Firewall.Sku.Name
    SkuTier           = $config.Networking.AppVNet.Firewall.Sku.Tier
    FirewallPolicyId  = $appVNetFirewallPolicy.Id
    PublicIpAddress   = $appVNetFirewallPublicIP
    
}
$appVNetFirewall = New-AzFirewall @appVNetFirewallParams

# Validate creation
if (-not $appVNetFirewall) {
    Write-Host "Failed to create Azure Firewall '$($config.Networking.AppVNet.Firewall.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Azure Firewall '$($appVNetFirewall.Name)' created successfully with Id '$($appVNetFirewall.Id)'." -ForegroundColor Green
}


# ------------------------
# Create Virtual Machines
# ------------------------

# Create VM1

$vm1BaseParams = @{
    VMName = $config.VirtualMachines.VM1.Name # e.g., 'VM1'
    VMSize = $config.VirtualMachines.Size     # e.g., 'Standard_D2s_v6'
}
$vm1 = New-AzVMConfig @vm1BaseParams

$vm1ImageParams = @{
    VM            = $vm1
    PublisherName = $config.VirtualMachines.Image.Publisher # e.g., 'canonical'
    Offer         = $config.VirtualMachines.Image.Offer     # e.g., 'ubuntu-24_04-lts'
    Skus          = $config.VirtualMachines.Image.Sku       # e.g., 'minimal'
    Version       = $config.VirtualMachines.Image.Version   # e.g., 'latest'
}
$vm1 = Set-AzVMSourceImage @vm1ImageParams

$vm1OsDiskParams = @{
    VM                 = $vm1 
    Name               = "$($config.VirtualMachines.VM1.Name)-osdisk"
    CreateOption       = $config.VirtualMachines.Disk.CreateOption       # e.g., 'FromImage'
    DiskSizeInGB       = $config.VirtualMachines.Disk.SizeGB             # e.g., 30
    StorageAccountType = $config.VirtualMachines.Disk.StorageAccountType # e.g., 'Standard_LRS'
    Caching            = $config.VirtualMachines.Disk.Caching            # e.g., 'ReadWrite'
}
$vm1 = Set-AzVMOSDisk @vm1OsDiskParams

$vm1OsParams = @{
    VM           = $vm1
    Linux        = $true
    ComputerName = $config.VirtualMachines.VM1.Name
    Credential   = $vmCredentials
}
$vm1 = Set-AzVMOperatingSystem @vm1OsParams

$vm1NicParams = @{
    VM = $vm1
    Id = $vm1Nic.Id
}
$vm1 = Add-AzVMNetworkInterface @vm1NicParams

$vm1DeploymentParams = @{
    ResourceGroupName = $resourceGroup.ResourceGroupName # e.g., 'RG1'
    Location          = $resourceGroup.Location                 # e.g., 'eastus'
    VM                = $vm1
}
$vm1DeploymentResult = New-AzVM @vm1DeploymentParams

# Validate deployment result
if (-not $vm1DeploymentResult) {
    Write-Host "Failed to deploy Virtual Machine '$($config.VirtualMachines.VM1.Name)'." -ForegroundColor Red
    exit
}
else {
    Write-Host "Deployment of Virtual Machine '$($config.VirtualMachines.VM1.Name)' initiated successfully with status code $($vm1DeploymentResult.StatusCode)." -ForegroundColor Green
}


# Create VM2

$vm2BaseParams = @{
    VMName = $config.VirtualMachines.VM2.Name # e.g., 'VM2'
    VMSize = $config.VirtualMachines.Size     # e.g., 'Standard_D2s_v6'
}
$vm2 = New-AzVMConfig @vm2BaseParams

$vm2ImageParams = @{
    VM            = $vm2
    PublisherName = $config.VirtualMachines.Image.Publisher # e.g., 'canonical'
    Offer         = $config.VirtualMachines.Image.Offer     # e.g., 'ubuntu-24_04-lts'
    Skus          = $config.VirtualMachines.Image.Sku       # e.g., 'minimal'
    Version       = $config.VirtualMachines.Image.Version   # e.g., 'latest'
}
$vm2 = Set-AzVMSourceImage @vm2ImageParams

$vm2OsDiskParams = @{
    VM                 = $vm2
    Name               = "$($config.VirtualMachines.VM2.Name)-osdisk"
    CreateOption       = $config.VirtualMachines.Disk.CreateOption       # e.g., 'FromImage'
    DiskSizeInGB       = $config.VirtualMachines.Disk.SizeGB             # e.g., 30
    StorageAccountType = $config.VirtualMachines.Disk.StorageAccountType # e.g., 'Standard_LRS'
    Caching            = $config.VirtualMachines.Disk.Caching            # e.g., 'ReadWrite'
}
$vm2 = Set-AzVMOSDisk @vm2OsDiskParams

$vm2OsParams = @{
    VM           = $vm2
    Linux        = $true
    ComputerName = $config.VirtualMachines.VM2.Name
    Credential   = $vmCredentials
}
$vm2 = Set-AzVMOperatingSystem @vm2OsParams

$vm2NicParams = @{
    VM = $vm2
    Id = $vm2Nic.Id
}
$vm2 = Add-AzVMNetworkInterface @vm2NicParams

$vm2DeploymentParams = @{
    ResourceGroupName = $resourceGroup.ResourceGroupName # e.g., 'RG1'
    Location          = $resourceGroup.Location                 # e.g., 'eastus'
    VM                = $vm2
}
$vm2DeploymentResult = New-AzVM @vm2DeploymentParams

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
