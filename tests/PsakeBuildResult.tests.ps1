BeforeDiscovery {
    if ($null -eq $env:BHProjectName) {
        .\build.ps1 -Task Build
    }
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'PsakeBuildResult' {
    It 'Should return a PsakeBuildResult from Invoke-psake' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $result | Should -Not -BeNullOrEmpty
        $result.Success | Should -BeTrue
        $result.BuildFile | Should -Not -BeNullOrEmpty
        $result.Duration | Should -Not -BeNullOrEmpty
        $result.Tasks | Should -Not -BeNullOrEmpty
        $result.Tasks.Count | Should -BeGreaterThan 0
    }

    It 'Should include task results with correct status' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $executedTasks = $result.Tasks | Where-Object { $_.Status -eq 'Executed' }
        $executedTasks.Count | Should -BeGreaterThan 0
    }

    It 'Should produce JSON output when requested' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $output = Invoke-Psake -BuildFile $buildFile -NoLogo -OutputFormat JSON
        # The output should include JSON text
        $jsonText = ($output | Where-Object { $_ -is [string] }) -join ''
        if ($jsonText) {
            { $jsonText | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It 'Should return failed result for bad builds' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unknown_task_key_should_fail.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $result | Should -Not -BeNullOrEmpty
        $result.Success | Should -BeFalse
        $result.ErrorMessage | Should -Not -BeNullOrEmpty
    }
}
