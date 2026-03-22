BeforeDiscovery {
    if ($null -eq $env:BHProjectName) {
        .\build.ps1 -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Declarative Task Syntax' {
    It 'Should accept declarative hashtable syntax' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_task_syntax_should_pass.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should reject unknown keys in task definition' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unknown_task_key_should_fail.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeFalse
        $psake.error_message | Should -Match 'Unknown task definition key'
    }

    It 'Should accept hashtable Properties syntax' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_properties_hashtable_should_pass.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should validate Version declaration' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'version_declaration_should_pass.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should reject version mismatch' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'version_mismatch_should_fail.ps1'
        $result = Invoke-Psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeFalse
    }
}
