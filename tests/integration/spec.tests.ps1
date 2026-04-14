BeforeDiscovery {
    $buildFiles = Get-ChildItem $PSScriptRoot/../../specs/*.ps1
    $script:testCases = $buildFiles | ForEach-Object {
        @{
            Name     = $_.Name
            FullName = $_.FullName
        }
    }
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
Describe 'PSake specs' {
    BeforeAll {
        $psake.run_by_psake_build_tester = $true

        $script:psakeParams = @{
            Parameters        = @{
                p1 = 'v1'
                p2 = 'v2'
            }
            Properties        = @{
                x = '1'
                y = '2'
            }
            Initialization    = {
                if (-not $container) {
                    $container = @{}
                }
                $container.bar = 'bar'
                $container.baz = 'baz'
                $bar = 2
                $baz = 3
            }
            NoLogo            = $true
            ErrorAction       = 'SilentlyContinue'
            WarningAction     = 'SilentlyContinue'
            InformationAction = 'SilentlyContinue'

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

        # Check if spec requires Windows and skip on non-Windows platforms.
        # PS 5.1 on Windows has no $IsWindows variable; its absence implies Windows.
        $isWindowsPlatform = !(Test-Path Variable:\IsWindows) -or $IsWindows
        $firstLine = Get-Content $FullName -TotalCount 1
        if ($firstLine -match '# Requires: Windows' -and -not $isWindowsPlatform) {
            Set-ItResult -Inconclusive -Because "Windows-only spec, skipping on non-Windows."
            return
        }

        # Check if there is a framework defined in the spec file is installed.
        if (-not (Test-BuildEnvironment -BuildFile $FullName )) {
            Set-ItResult -Inconclusive -Because "Required framework for this spec is not available. Skipping test."
            return
        }

        # Run the build and toss out all the output. We just want to check the success/failure and error message properties.
        $output = Invoke-Psake @psakeParams 6> $null
        # Check $psake var for legacy uses
        # and $output for the new returned types.
        $psake.build_success | Should -Be $expectedResult -Because "Expected build_success to be $expectedResult for spec file [$Name]."
        $output.Success | Should -Be $expectedResult -Because "Expected Success property to be $expectedResult in output object for spec file [$Name]."

        if ($shouldHaveError) {
            $psake.error_message | Should -Not -BeNullOrEmpty -Because 'Expected an error message on $psake when build fails.'
            $output.ErrorMessage | Should -Not -BeNullOrEmpty -Because 'Expected an error message on output object when build fails.'
            $output.ErrorRecord | Should -Not -BeNullOrEmpty -Because 'Expected an error record on output object when build fails.'
        } else {
            $psake.error_message | Should -BeNullOrEmpty -Because 'Did not expect an error message on $psake when build succeeds.'
            $output.ErrorMessage | Should -BeNullOrEmpty -Because 'Did not expect an error message on output object when build succeeds.'
            $output.ErrorRecord | Should -BeNullOrEmpty -Because 'Did not expect an error record on output object when build succeeds.'
        }
    }
}
