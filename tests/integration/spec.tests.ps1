Describe 'PSake specs' {
    BeforeDiscovery {
        $buildFiles = Get-ChildItem $PSScriptRoot/../../specs/*.ps1
        $script:testCases = $buildFiles | ForEach-Object {
            @{
                Name     = $_.Name
                FullName = $_.FullName
            }
        }
    }

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

        $oldPSPath = $env:PSModulePath
        $env:PSModulePath += "$([IO.Path]::PathSeparator)$PSScriptRoot/../../specs/SharedTaskModules"
    }

    AfterAll {
        $env:PSModulePath = $oldPSPath
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

        $output = Invoke-psake @psakeParams
        Write-Debug "build_success=$($psake.build_success), expectedResult=$expectedResult"
        Write-Debug "output=$output"
        $psake.build_success | Should -Be $expectedResult

        if ($shouldHaveError) {
            $psake.error_message | Should -Not -BeNullOrEmpty
        } else {
            $psake.error_message | Should -BeNullOrEmpty
        }
    }
}
