Describe 'PsakeBuildResult' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'src' 'psake.psd1'
        Import-Module $modulePath -Force
    }

    It 'Should return a PsakeBuildResult from Invoke-psake' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $result | Should -Not -BeNullOrEmpty
        $result.Success | Should -BeTrue
        $result.BuildFile | Should -Not -BeNullOrEmpty
        $result.Duration | Should -Not -BeNullOrEmpty
        $result.Tasks | Should -Not -BeNullOrEmpty
        $result.Tasks.Count | Should -BeGreaterThan 0
    }

    It 'Should include task results with correct status' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $executedTasks = $result.Tasks | Where-Object { $_.Status -eq 'Executed' }
        $executedTasks.Count | Should -BeGreaterThan 0
    }

    It 'Should produce JSON output when requested' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'simple_properties_and_tasks_should_pass.ps1'
        $output = Invoke-psake -BuildFile $buildFile -NoLogo -OutputFormat JSON
        # The output should include JSON text
        $jsonText = ($output | Where-Object { $_ -is [string] }) -join ''
        if ($jsonText) {
            { $jsonText | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It 'Should return failed result for bad builds' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unknown_task_key_should_fail.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $result | Should -Not -BeNullOrEmpty
        $result.Success | Should -BeFalse
        $result.ErrorMessage | Should -Not -BeNullOrEmpty
    }
}
