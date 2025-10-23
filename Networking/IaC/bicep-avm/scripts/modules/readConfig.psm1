function Read-Config {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptDirectory,
        [Parameter()]
        [string]$ConfigFileName = 'config.psd1'
    )

    # Identify the root directory (one level up from script directory)
    $RootDirectory = Resolve-Path (Join-Path -Path $ScriptDirectory -ChildPath '..') | Select-Object -ExpandProperty Path

    # Path to the configuration file
    $ConfigPath = Join-Path -Path $ScriptDirectory -ChildPath $ConfigFileName
    Write-Host "Loading configuration from: $ConfigPath" -ForegroundColor Yellow

    # Check if the configuration file exists, throw if not
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    # Load the configuration
    $Config = Import-PowerShellDataFile -Path $ConfigPath

    # Add script and root directories to the configuration for later use
    $Config.ScriptDirectory = $ScriptDirectory
    $Config.RootDirectory = $RootDirectory

    if ($PSCmdlet.MyInvocation.BoundParameters['Debug']) {
        Write-Debug "`nLoaded Configurations:"
        foreach ($key in $Config.Keys) {
            Write-Debug "- ${key}: $($Config[$key])"
        }
    }

    Write-Host "Configuration loaded successfully." -ForegroundColor Green
    
    return $Config
}

<#!
.SYNOPSIS
    Loads and validates the deployment configuration file.
.DESCRIPTION
    Loads the specified config.psd1 file, adds script/root directory properties, and outputs the configuration for verification.
.PARAMETER ScriptDirectory
    The directory where the script is located (typically $PSScriptRoot).
.PARAMETER ConfigFileName
    The name of the configuration file (default: config.psd1).
.EXAMPLE
    $config = Load-Config -ScriptDirectory $PSScriptRoot
.NOTES
    Throws if the configuration file is missing.
#>
