
Describe 'Connect-AzAndSelectSubscription' {

    BeforeAll {
        # Save original env vars
        $originalEnv = @{
            GITHUB_ACTIONS        = $env:GITHUB_ACTIONS
            AZURE_CLIENT_ID       = $env:AZURE_CLIENT_ID
            AZURE_CLIENT_SECRET   = $env:AZURE_CLIENT_SECRET
            AZURE_TENANT_ID       = $env:AZURE_TENANT_ID
            AZURE_SUBSCRIPTION_ID = $env:AZURE_SUBSCRIPTION_ID
        }

        Remove-Module "azureLogin" -Force
        Import-Module "$PSScriptRoot/azureLogin.psm1" -Force
    }

    AfterAll {
        # Restore original env vars
        $env:GITHUB_ACTIONS = $originalEnv['GITHUB_ACTIONS']
        $env:AZURE_CLIENT_ID = $originalEnv['AZURE_CLIENT_ID']
        $env:AZURE_CLIENT_SECRET = $originalEnv['AZURE_CLIENT_SECRET']
        $env:AZURE_TENANT_ID = $originalEnv['AZURE_TENANT_ID']
        $env:AZURE_SUBSCRIPTION_ID = $originalEnv['AZURE_SUBSCRIPTION_ID']
    }

    Context 'Manual execution (device authentication)' {
        BeforeEach {
            $env:GITHUB_ACTIONS = $null
        }
        It 'returns context and subscription on successful login' {
            Mock Connect-AzAccount { @{ Account = 'user@contoso.com' } } -ParameterFilter { $UseDeviceAuthentication } -ModuleName azureLogin
            Mock Get-AzContext { @{ Account = 'user@contoso.com'; Subscription = @{ Name = 'TestSub'; Id = 'subid' } } } -ModuleName azureLogin
            $result = Connect-AzAndSelectSubscription
            $result.Account | Should -Be 'user@contoso.com'
            $result.Subscription.Name | Should -Be 'TestSub'
        }
        It 'throws if login fails' {
            Mock Connect-AzAccount { $null } -ParameterFilter { $UseDeviceAuthentication } -ModuleName azureLogin
            { Connect-AzAndSelectSubscription } | Should -Throw 'Login failed. Please check your credentials or network connection.'
        }
        It 'throws if context is missing' {
            Mock Connect-AzAccount { @{ Account = 'user@contoso.com' } } -ParameterFilter { $UseDeviceAuthentication } -ModuleName azureLogin
            Mock Get-AzContext { @{ Account = $null } } -ModuleName azureLogin
            { Connect-AzAndSelectSubscription } | Should -Throw 'No Azure context found after login.'
        }
    }

    Context 'GitHub Actions execution (service principal)' {
        BeforeEach {
            $env:GITHUB_ACTIONS = 'true'
            $env:AZURE_CLIENT_ID = 'clientid'
            $env:AZURE_CLIENT_SECRET = 'secret'
            $env:AZURE_TENANT_ID = 'tenantid'
            $env:AZURE_SUBSCRIPTION_ID = 'subid'
        }
        It 'returns context and subscription on successful service principal login' {
            Mock Connect-AzAccount { @{ Account = 'sp@contoso.com' } } -ModuleName azureLogin
            Mock Get-AzContext { @{ Account = 'sp@contoso.com'; Subscription = @{ Name = 'GHSub'; Id = 'subid' } } } -ModuleName azureLogin
            $result = Connect-AzAndSelectSubscription
            $result.Account | Should -Be 'sp@contoso.com'
            $result.Subscription.Name | Should -Be 'GHSub'
        }
        It 'throws if service principal login fails' {
            Mock Connect-AzAccount { $null } -ModuleName azureLogin
            { Connect-AzAndSelectSubscription } | Should -Throw 'Service principal login failed. Please check your credentials or network connection.'
        }
        It 'throws if required env vars are missing' {
            $env:AZURE_CLIENT_ID = $null
            { Connect-AzAndSelectSubscription } | Should -Throw 'Missing one or more required Azure service principal environment variables (AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID).'
        }
        It 'throws if context is missing after service principal login' {
            Mock Connect-AzAccount { @{ Account = 'sp@contoso.com' } } -ParameterFilter { $ServicePrincipal } -ModuleName azureLogin
            Mock Get-AzContext { @{ Account = $null } } -ModuleName azureLogin
            { Connect-AzAndSelectSubscription } | Should -Throw 'No Azure context found after login.'
        }
    }
}
