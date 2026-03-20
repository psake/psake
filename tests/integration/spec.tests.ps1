BeforeDiscovery {
    $buildFiles = Get-ChildItem $PSScriptRoot/../../specs/*.ps1
    $script:testCases = $buildFiles | ForEach-Object {
        @{
            Name     = $_.Name
            FullName = $_.FullName
        }
    }
    Import-Module $PSScriptRoot/../../output/psake
}
Describe 'PSake specs' {
    BeforeAll {
        $psake.run_by_psake_build_tester = $true

        $script:psakeParams = @{
            Parameters     = @{
                p1 = 'v1'
                p2 = 'v2'
            }
            Properties     = @{
                x = '1'
                y = '2'
            }
            Initialization = {
                if (-not $container) {
                    $container = @{}
                }
                $container.bar = 'bar'
                $container.baz = 'baz'
                $bar = 2
                $baz = 3
            }
        }

        $script:oldPSPath = $env:PSModulePath
        $paths = $env:PSModulePath -split [IO.Path]::PathSeparator
        $paths += (Resolve-Path "$PSScriptRoot/../../specs/SharedTaskModules").Path
        $env:PSModulePath = ($paths -join [IO.Path]::PathSeparator)
    }

    AfterAll {
        $env:PSModulePath = $script:oldPSPath
    }

    It '<Name>' -TestCases $script:testCases {
        $script:psakeParams.BuildFile = $FullName
        $shouldHaveError = $false

        if ($Name.EndsWith('_should_pass.ps1')) {
            $expectedResult = $true
        } elseif ($Name.EndsWith('_should_fail.ps1')) {
            $expectedResult = $false
            $shouldHaveError = $true
        } else {
            throw "Invalid specification syntax. Specs file [$Name] should end with _should_pass or _should_fail."
        }

        # Check if there is a framework defined in the spec file is installed.
        if (-not (Test-BuildEnvironment -BuildFile $FullName )) {
            Set-ItResult -Inconclusive -Because "Required framework for this spec is not available. Skipping test."
            return
        }

        $output = Invoke-Psake @psakeParams -OutputFormat JSON
        $psake.build_success | Should -Be $expectedResult

        if ($shouldHaveError) {
            $psake.error_message | Should -Not -BeNullOrEmpty
        } else {
            $psake.error_message | Should -BeNullOrEmpty
        }
    }
}
