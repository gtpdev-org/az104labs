# Pester test suite for Get-SystemInfoSummary.ps1
# Place in the same folder as the script under test



BeforeAll {
    # Use $PSScriptRoot for robust path resolution
    $script:here = $PSScriptRoot
    . "$script:here/Get-SysInfo.ps1"
    $script:testFile = Join-Path $script:here 'sysinfo_test.txt'
}

Describe 'Get-SystemInfoSummary' -Tag 'Unit' {
    AfterEach {
        # Clean up test file after each test
        if (Test-Path $script:testFile) { Remove-Item $script:testFile -Force }
    }

    It 'Creates a sysinfo file with expected content' -Tag 'File' {
        Get-SystemInfoSummary -OutputPath $script:testFile | Out-Null
        (Test-Path $script:testFile) | Should -BeTrue
        $content = @(Get-Content $script:testFile)
        $content | Should -Not -BeNullOrEmpty
        $count = $content.Count
        $count | Should -Be 3
        $content[0] | Should -Match '^OS Version'
        $content[1] | Should -Match '^Hostname'
        $content[2] | Should -Match '^Total Memory'
    }

    It 'Returns a PSCustomObject with -PassThru' -Tag 'Object' {
        $result = Get-SystemInfoSummary -OutputPath $script:testFile -PassThru
        $result | Should -BeOfType 'System.Management.Automation.PSCustomObject'
        $result.OSVersion | Should -Not -BeNullOrEmpty
        $result.Hostname | Should -Not -BeNullOrEmpty
        $result.TotalMemoryGB | Should -BeGreaterThan 0
        $result.OutputPath | Should -Be $script:testFile
    }

    It 'Throws no error for normal execution' -Tag 'Error' {
        { Get-SystemInfoSummary -OutputPath $script:testFile } | Should -Not -Throw
    }

    It 'Honors ShouldProcess (WhatIf)' -Tag 'WhatIf' {
        # Should not create the file when -WhatIf is used
        Get-SystemInfoSummary -OutputPath $script:testFile -WhatIf | Out-Null
        (Test-Path $script:testFile) | Should -BeFalse
    }
}
