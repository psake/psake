Describe 'Compile-BuildPlan' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'src' 'psake.psd1'
        Import-Module $modulePath -Force
    }

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
        $plan.Success | Should -BeFalse
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

    It 'Should include TaskMap with all tasks' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_task_syntax_should_pass.ps1'
        $plan = Get-PsakeBuildPlan -BuildFile $buildFile
        $plan.TaskMap | Should -Not -BeNullOrEmpty
        $plan.TaskMap.ContainsKey('clean') | Should -BeTrue
        $plan.TaskMap.ContainsKey('build') | Should -BeTrue
        $plan.TaskMap['build'].DependsOn | Should -Contain 'Clean'
    }
}
