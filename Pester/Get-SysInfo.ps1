<#
.SYNOPSIS
Gets a summary of system information and writes it to a text file.

.DESCRIPTION
This script/function collects the OS version, hostname, and total memory, then writes the summary to a specified output file (default: sysinfo.txt in the script directory). Optionally returns the summary object if -PassThru is specified.

.PARAMETER OutputPath
The path to the output file. Defaults to 'sysinfo.txt' in the script directory.

.PARAMETER PassThru
If specified, returns the system information object to the pipeline.

.EXAMPLE
Get-SystemInfoSummary

.EXAMPLE
Get-SystemInfoSummary -OutputPath 'C:\Temp\sysinfo.txt' -PassThru
#>
function Get-SystemInfoSummary {
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
	param(
		[Parameter(Position=0)]
		[string]$OutputPath = (Join-Path $PSScriptRoot 'sysinfo.txt'),

		[Parameter()]
		[switch]$PassThru
	)

	process {
		try {
			if ($IsWindows) {
				$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
				$cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
				$osVersion = "$($os.Caption) $($os.Version)"
				$hostname = $env:COMPUTERNAME
				$totalMemory = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
			} else {
				# Try to get OS version from /etc/os-release or uname
				if (Test-Path '/etc/os-release') {
					$osInfo = Get-Content /etc/os-release | Where-Object { $_ -match '^PRETTY_NAME=' }
					$osVersion = $osInfo -replace 'PRETTY_NAME="?','' -replace '"$',''
				} else {
					$osVersion = (uname -a)
				}
				$hostname = $(hostname)
				# Get total memory in GB using 'free' if available
				$memLine = $(free -b 2>/dev/null | Where-Object { $_ -match '^Mem:' })
				if ($memLine) {
					$totalMemory = [math]::Round(($memLine -split '\s+')[1] / 1GB, 2)
				} else {
					$totalMemory = 'Unknown'
				}
			}

			$summary = @()
			$summary += "OS Version: $osVersion"
			$summary += "Hostname: $hostname"
			$summary += "Total Memory (GB): $totalMemory"

			if ($PSCmdlet.ShouldProcess($OutputPath, 'Write system information summary to file')) {
				$summary | Set-Content -Path $OutputPath -Encoding UTF8
				Write-Verbose "System information written to $OutputPath"
			}

			if ($PassThru.IsPresent) {
				[PSCustomObject]@{
					OSVersion   = $osVersion
					Hostname    = $hostname
					TotalMemoryGB = $totalMemory
					OutputPath  = $OutputPath
				}
			}
		}
		catch {
			$PSCmdlet.WriteError((New-Object System.Management.Automation.ErrorRecord $_.Exception, 'SysInfoError', 'NotSpecified', $null))
		}
	}
}

