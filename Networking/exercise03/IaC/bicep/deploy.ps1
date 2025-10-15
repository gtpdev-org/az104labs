# --------------------------------
# Azure Resource Deployment Script
# --------------------------------

Write-Host "=== Azure Resource Bicep Deployment Script ===" -ForegroundColor Cyan

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
    Name        = $config.ResourceGroupName
    Location    = $config.Location
    ErrorAction = 'SilentlyContinue'
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
# Deploy the Bicep template
# -------------------------------

Write-Host "`nDeploying Bicep template '$($config.BicepFile)' to Resource Group '$($config.ResourceGroupName)'..." -ForegroundColor Yellow

$bicepDeploymentConfig = @{
    ResourceGroupName     = $config.ResourceGroupName
    TemplateFile          = $config.BicepFile
    TemplateParameterFile = $config.ParametersFile
    ErrorAction           = 'SilentlyContinue'
}
$bicepDeployment = New-AzResourceGroupDeployment @bicepDeploymentConfig

# Validate the result
if (-not $bicepDeployment) {
    Write-Host "Failed to deploy Bicep template '$($config.BicepFile)' to Resource Group '$($config.ResourceGroupName)'. Please check your parameters and Azure permissions." -ForegroundColor Red
    exit
}
else {
    Write-Host "Bicep template deployed successfully!" -ForegroundColor Green
}


# -------------------------------
# Completion Message
# -------------------------------

Write-Host "`nDeployment completed successfully!" -ForegroundColor Cyan
