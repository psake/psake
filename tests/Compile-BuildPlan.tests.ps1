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
Describe 'Compile-BuildPlan' {
    It 'Should compile a valid build plan' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan | Should -Not -BeNullOrEmpty
        $plan.IsValid | Should -BeTrue
        $plan.Tasks.Count | Should -BeGreaterThan 0
        $plan.ExecutionOrder.Count | Should -BeGreaterThan 0
    }

    It 'Should detect circular dependencies' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'compile_phase_circular_dependency_should_fail.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeFalse
        $plan.ValidationErrors | Should -Not -BeNullOrEmpty
        ($plan.ValidationErrors -join ' ') | Should -Match 'Circular'
    }

    It 'Should detect missing task references' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'compile_phase_missing_task_should_fail.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeFalse
        $plan.ValidationErrors | Should -Not -BeNullOrEmpty
        ($plan.ValidationErrors -join ' ') | Should -Match 'does not exist'
    }

    It 'Should resolve execution order correctly' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeTrue
        # Clean should come before Compile, Compile before Test
        $cleanIdx = [array]::IndexOf($plan.ExecutionOrder, 'clean')
        $compileIdx = [array]::IndexOf($plan.ExecutionOrder, 'compile')
        $testIdx = [array]::IndexOf($plan.ExecutionOrder, 'test')
        $cleanIdx | Should -BeLessThan $compileIdx
        $compileIdx | Should -BeLessThan $testIdx
    }

    It 'Should exclude unreachable tasks from TaskMap' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unreachable_task_excluded_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeTrue
        $plan.TaskMap.ContainsKey('deploy') | Should -BeFalse
        $plan.Tasks | Where-Object { $_.Name -eq 'deploy' } | Should -BeNullOrEmpty
    }

    It 'Should include only reachable tasks in TaskMap' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unreachable_task_excluded_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.IsValid | Should -BeTrue
        $plan.TaskMap.Keys | Should -HaveCount $plan.ExecutionOrder.Count
        foreach ($key in $plan.TaskMap.Keys) {
            $plan.ExecutionOrder | Should -Contain $key
        }
    }

    It 'Should include TaskMap with all tasks' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_task_syntax_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.TaskMap | Should -Not -BeNullOrEmpty
        $plan.TaskMap.ContainsKey('clean') | Should -BeTrue
        $plan.TaskMap.ContainsKey('build') | Should -BeTrue
        $plan.TaskMap['build'].DependsOn | Should -Contain 'Clean'
    }
}
