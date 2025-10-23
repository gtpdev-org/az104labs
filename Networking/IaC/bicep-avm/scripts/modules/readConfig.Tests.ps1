BeforeAll {
    $script:here = $PSScriptRoot
    $script:moduleUnderTest = 'readConfig.psm1'
    $script:moduleUnderTestPath = Join-Path $script:here $script:moduleUnderTest
    Get-Module | Remove-Module -Force
    Import-Module $script:moduleUnderTestPath -Force
}

Describe 'Read-Config' {
    Context 'Valid configuration file' {
        It 'Returns a config object with expected properties' {
            $scriptDir = $script:here
            $testConfigFile = 'test.config.psd1'
            $configPath = Join-Path $scriptDir $testConfigFile
            # Create a temporary config file
            @{
                ResourceGroupName = 'TestRG'
                Location = 'eastus'
            } | Export-Clixml -Path $configPath
            # Convert to psd1 format
            $psd1Content = "@{`n    ResourceGroupName = 'TestRG'`n    Location = 'eastus'`n}"
            Set-Content -Path $configPath -Value $psd1Content

            $config =  Read-Config -ScriptDirectory $scriptDir -ConfigFileName $testConfigFile

            $config.ResourceGroupName | Should -Be 'TestRG'
            $config.Location | Should -Be 'eastus'
            $config.ScriptDirectory | Should -Be $scriptDir
            $config.RootDirectory | Should -Not -BeNullOrEmpty
            Remove-Item $configPath
        }
    }
    Context 'Debug flag output' {
        It 'Outputs debug information when -Debug is used' {
            $scriptDir = $here
            $configFile = 'debug.config.psd1'
            $configPath = Join-Path $scriptDir $configFile
            $psd1Content = "@{`n    ResourceGroupName = 'DebugRG'`n    Location = 'centralus'`n}"
            Set-Content -Path $configPath -Value $psd1Content
            
            $output = & { Read-Config -ScriptDirectory $scriptDir -ConfigFileName $configFile -Debug } 4>&1

            $output | Should -BeOfType 'Hashtable'
            $output.Keys | Should -Contain 'ResourceGroupName'
            $output.Keys | Should -Contain 'Location'
            $output.Keys | Should -Contain 'RootDirectory'
            $output.Keys | Should -Contain 'ScriptDirectory'
            $output['ResourceGroupName'] | Should -Be 'DebugRG'
            $output['Location'] | Should -Be 'centralus'
            $output['RootDirectory'] | Should -Not -BeNullOrEmpty
            $output['ScriptDirectory'] | Should -Not -BeNullOrEmpty

            Remove-Item $configPath
        }
    }
    Context 'Missing configuration file' {
        It 'Throws when config file does not exist' {
            $missingConfigFile = 'missing.config.psd1'
            { Read-Config -ScriptDirectory $script:here -ConfigFileName $missingConfigFile } | Should -Throw "Configuration file not found: ${script:here}/${missingConfigFile}"
        }
    }
    Context 'Default parameter values' {
        It 'Uses default config file name when not specified' {
            $scriptDir = $here
            $configFile = 'config.psd1'
            $configPath = Join-Path $scriptDir $configFile
            $psd1Content = "@{`n    ResourceGroupName = 'DefaultRG'`n    Location = 'westus'`n}"
            Set-Content -Path $configPath -Value $psd1Content

            $config = Read-Config -ScriptDirectory $scriptDir
            
            $config.ResourceGroupName | Should -Be 'DefaultRG'
            $config.Location | Should -Be 'westus'
            Remove-Item $configPath
        }
    }
}
