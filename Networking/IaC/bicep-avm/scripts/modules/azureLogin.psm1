
function Connect-AzAndSelectSubscription {
    <#
    .SYNOPSIS
    Logs in to Azure using device authentication (manual) or service principal (GitHub Actions) and selects the current subscription context.
    .DESCRIPTION
    Encapsulates Azure login and subscription selection logic. Returns a hashtable with Account, Context, and Subscription info. Throws on failure.
    .OUTPUTS
    [hashtable] with keys: Account, Context, Subscription
    #>
    [CmdletBinding()]
    param()

    $isGitHubActions = $env:GITHUB_ACTIONS -eq 'true'

    if ($isGitHubActions) {
        Write-Host "Detected GitHub Actions environment. Authenticating using service principal..." -ForegroundColor Yellow
        $clientId     = $env:AZURE_CLIENT_ID
        $clientSecret = $env:AZURE_CLIENT_SECRET
        $tenantId     = $env:AZURE_TENANT_ID
        $subscriptionId = $env:AZURE_SUBSCRIPTION_ID

        if (-not $clientId -or -not $clientSecret -or -not $tenantId -or -not $subscriptionId) {
            throw "Missing one or more required Azure service principal environment variables (AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID)."
        }

        $credential = New-Object System.Management.Automation.PSCredential($clientId, (ConvertTo-SecureString $clientSecret -AsPlainText -Force))
        $account = Connect-AzAccount -ServicePrincipal -Tenant $tenantId -SubscriptionId $subscriptionId -Credential $credential

        if (-not $account) {
            throw "Service principal login failed. Please check your credentials or network connection."
        }
    } else {
        Write-Host "Logging in to Azure (manual/device authentication)..." -ForegroundColor Yellow
        $account = Connect-AzAccount -UseDeviceAuthentication -ErrorAction SilentlyContinue
        if (-not $account) {
            throw "Login failed. Please check your credentials or network connection."
        }
    }

    $currentContext = Get-AzContext
    if (-not $currentContext.Account) {
        throw "No Azure context found after login."
    }

    $subscription = $currentContext.Subscription
    Write-Host "Login successful.`nAccount: $($currentContext.Account)`nSubscription: $($subscription.Name) ($($subscription.Id))" -ForegroundColor Green
    return @{ Account = $currentContext.Account; Context = $currentContext; Subscription = $subscription }
}
