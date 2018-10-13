
#Remove-Module -Name psake -ErrorAction SilentlyContinue
#Import-Module -Name "$PSScriptRoot/../../src/psake.psd1"

$psake.run_by_psake_build_tester = $true

$buildFiles = Get-ChildItem $PSScriptRoot/../../specs/*.ps1
$testResults = @()

#$non_existant_buildfile = '' | Select-Object -Property Name, FullName
#$non_existant_buildfile.Name = 'specifying_a_non_existant_buildfile_should_fail.ps1'
#$non_existant_buildfile.FullName = 'c:\specifying_a_non_existant_buildfile_should_fail.ps1'
#$buildFiles += $non_existant_buildfile

describe 'PSake specs' {

    BeforeAll {
        $oldPSPath = $env:PSModulePath
        $env:PSModulePath += "$([IO.Path]::PathSeparator)$PSScriptRoot/../../specs/SharedTaskModules"
    }

    AfterAll {
        $env:PSModulePath = $oldPSPath
    }

    $psakeParams = @{
        Parameters = @{
            p1 = 'v1'
            p2 = 'v2'
        }
        Properties = @{
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

    foreach ($buildFile in $buildFiles) {

        it "$($buildFile.BaseName)" {

            $psakeParams.BuildFile = $buildFile.FullName
            $shouldHaveError = $false

            if ($buildFile.Name.EndsWith('_should_pass.ps1')) {
                $expectedResult = $true
            } elseif ($buildFile.Name.EndsWith('_should_fail.ps1')) {
                $expectedResult = $false
                $shouldHaveError = $true
            } else {
                throw "Invalid specification syntax. Specs file [$($buildFile.BaseName)] should end with _should_pass or _should_fail."
            }

            Invoke-psake @psakeParams | Out-Null
            $psake.build_success | should -be $expectedResult

            if ($shouldHaveError) {
               $psake.error_message | should -not -be $null
            } else {
               $psake.error_message | should -be $null
            }
        }
    }
}
