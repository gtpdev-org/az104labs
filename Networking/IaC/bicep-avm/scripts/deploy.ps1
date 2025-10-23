Import-Module "$PSScriptRoot/modules/readConfig.psm1"
Import-Module "$PSScriptRoot/modules/azureLogin.psm1"

# --------------------------------
# Azure Resource Deployment Script
# --------------------------------

Write-Host "=== Azure Resource Bicep Deployment Script ===" -ForegroundColor Cyan

$config = Read-Config -ScriptDirectory $PSScriptRoot


# ---------------------------------------
# Login to Azure and select Subscription (using module)
# ---------------------------------------
try {
    $azLoginResult = Connect-AzAndSelectSubscription
    $currentContext = $azLoginResult.Context
    $subscription = $azLoginResult.Subscription
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit
}


# -------------------------------
# Resource Group Creation
# -------------------------------

# # Attempt to retrieve the Resource Group
# $existingRG = Get-AzResourceGroup -Name $config.ResourceGroupName -ErrorAction SilentlyContinue

# # Check if the Resource Group already exists
# # Remove it if in the same location, else exit
# if ($existingRG) {
#     Write-Host "`nResource Group '$($existingRG.ResourceGroupName)' already exists in location '$($existingRG.Location)'." -ForegroundColor Red
#     if ($existingRG.Location -eq $config.Location) {
#         Write-Host "Deleting existing Resource Group..." -ForegroundColor Red
#         Remove-AzResourceGroup -Name $config.ResourceGroupName -Force -Confirm:$false
#         Write-Host "Resource Group '$($config.ResourceGroupName)' deleted successfully." -ForegroundColor Green
#     }
#     else {
#         Write-Host "Please choose a different name or delete the existing Resource Group before proceeding." -ForegroundColor Yellow
#         exit
#     }
# }

# # Create the Resource Group
# Write-Host "`nCreating Resource Group '$($config.ResourceGroupName)' in '$($config.Location)'..." -ForegroundColor Yellow
# $resourceGroupConfig = @{
#     Name        = $config.ResourceGroupName
#     Location    = $config.Location
#     ErrorAction = 'SilentlyContinue'
# }
# $resourceGroup = New-AzResourceGroup @resourceGroupConfig

# # Validate the result
# if (-not $resourceGroup) {
#     Write-Host "Failed to create Resource Group '$($config.ResourceGroupName)'. Please check your parameters and Azure permissions." -ForegroundColor Red
#     exit
# }
# else {
#     Write-Host "Resource Group created successfully!" -ForegroundColor Green
# }


# -------------------------------
# Merge Bicep Parameters
# -------------------------------

# Identify the main parameters file path
$mainParamsPath = Join-Path -Path $config.RootDirectory -ChildPath $config.ParametersFile
Write-Host "`nMerging Bicep parameter files into: $($mainParamsPath)" -ForegroundColor Yellow

# Read main parameters file and convert parameters to hashtable for dynamic assignment
$mergedParameters = @{}
$originalParams = (Get-Content $mainParamsPath | ConvertFrom-Json).parameters
foreach ($p in $originalParams.PSObject.Properties) {
    $mergedParameters[$p.Name] = $p.Value
}

# Output the original parameters for verification
Write-Debug "`nOriginal parameters in main.parameters.json:" -ForegroundColor Cyan
$originalParams.PSObject.Properties | ForEach-Object { Write-Host "- $($_.Name): $($_.Value)" }

#Output the merged parameters hashtable for verification
Write-Host "`nMerged parameters hashtable before merging additional files:" -ForegroundColor Cyan
foreach ($key in $mergedParameters.Keys) {
    Write-Host "- ${key}: $($mergedParameters[$key])"
}

# Identify the parameters directory
$parametersDirectory = Join-Path -Path $config.RootDirectory -ChildPath $config.ParametersDirectory
Write-Host "Parameters directory: $parametersDirectory" -ForegroundColor Green

# Find all JSON parameter files recursively
$paramFiles = Get-ChildItem -Path $parametersDirectory -Filter *.json -Recurse

# Merge the parameters from each file into the main parameters hashtable
foreach ($file in $paramFiles) {
    Write-Host "Merging parameters from file: $($file.FullName)" -ForegroundColor Green
    $paramJson = Get-Content $file.FullName | ConvertFrom-Json
    
    foreach ($param in $paramJson.parameters.PSObject.Properties) {

        if ($null -eq $param.Value) {
            Write-Warning "Parameter '$($param.Name)' in file '$($file.FullName)' is null. Check the file structure."
        }
        else {
            $paramJson = ($param.Value | ConvertTo-Json -Depth 10)
            Write-Host " - Merging parameter: $($param.Name) with value: $($paramJson)" -ForegroundColor DarkGray
            $mergedParameters[$param.Name] = $paramJson
        }
    }
}

# Output the merged parameters hashtable for verification
Write-Host "`nMerged parameters hashtable after merging additional files:" -ForegroundColor Cyan
foreach ($key in $mergedParameters.Keys) {
    
    Write-Host """${key}"": $mergedParameters[$key]"

    ##Write-Host """${key}"": $($mergedParameters[$key] | Out-String)"

    # Write-Host """${key}"":"
    # $mergedParameters[$key] | Format-List | Out-String | Write-Host
}

# # Write merged parameters back to main.parameters.json
# $mainParams | ConvertTo-Json -Depth 10 | Set-Content $mainParamsPath

Write-Host "All parameters merged successfully." -ForegroundColor Green


# -------------------------------
# Deploy the Bicep template
# -------------------------------

# Write-Host "`nDeploying Bicep template '$($config.BicepFile)' to Resource Group '$($config.ResourceGroupName)'..." -ForegroundColor Yellow

# $bicepDeploymentConfig = @{
#     ResourceGroupName     = $config.ResourceGroupName
#     TemplateFile          = $config.BicepFile
#     TemplateParameterFile = $config.ParametersFile
# }
# $bicepDeployment = New-AzResourceGroupDeployment @bicepDeploymentConfig

# # Validate the result
# if (-not $bicepDeployment) {
#     Write-Host "Failed to deploy Bicep template '$($config.BicepFile)' to Resource Group '$($config.ResourceGroupName)'. Please check your parameters and Azure permissions." -ForegroundColor Red
#     exit
# }
# else {
#     Write-Host "Bicep template deployed successfully!" -ForegroundColor Green
# }


# -------------------------------
# Completion Message
# -------------------------------

Write-Host "`nDeployment completed successfully!" -ForegroundColor Cyan
