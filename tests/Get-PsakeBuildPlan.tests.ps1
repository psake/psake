BeforeDiscovery {
    if ($null -eq $env:BHProjectName) {
        .\build.ps1 -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'Output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Get-PsakeBuildPlan' {
    It 'Should return a build plan without executing tasks' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan | Should -Not -BeNullOrEmpty
        $plan.IsValid | Should -BeTrue
        $plan.BuildFile | Should -Not -BeNullOrEmpty
        $plan.Tasks | Should -Not -BeNullOrEmpty
        $plan.ExecutionOrder | Should -Not -BeNullOrEmpty
        $plan.TaskMap | Should -Not -BeNullOrEmpty
    }

    It 'Should expose task metadata for inspection' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_task_syntax_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.TaskMap['clean'].Description | Should -Be 'Clean build artifacts'
        $plan.TaskMap['build'].DependsOn | Should -Contain 'Clean'
    }

    It 'Should detect validation errors without executing' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'compile_phase_circular_dependency_should_fail.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeFalse
        $plan.ValidationErrors.Count | Should -BeGreaterThan 0
    }
}
