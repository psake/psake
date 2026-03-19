Describe 'Declarative Task Syntax' {
    BeforeAll {
        $modulePath = Join-Path $PSScriptRoot '..' 'src' 'psake.psd1'
        Import-Module $modulePath -Force
    }

    It 'Should accept declarative hashtable syntax' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_task_syntax_should_pass.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should reject unknown keys in task definition' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'unknown_task_key_should_fail.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeFalse
        $psake.error_message | Should -Match 'Unknown task definition key'
    }

    It 'Should accept hashtable Properties syntax' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'declarative_properties_hashtable_should_pass.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should validate Version declaration' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'version_declaration_should_pass.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeTrue
    }

    It 'Should reject version mismatch' {
        $buildFile = Join-Path $PSScriptRoot '..' 'specs' 'version_mismatch_should_fail.ps1'
        $result = Invoke-psake -BuildFile $buildFile -NoLogo -Quiet
        $psake.build_success | Should -BeFalse
    }
}
