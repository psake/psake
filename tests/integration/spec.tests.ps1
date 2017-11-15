
Remove-Module -Name psake -ErrorAction SilentlyContinue
Import-Module -Name "$PSScriptRoot/../../psake/psake.psd1"

$psake.run_by_psake_build_tester = $true

$buildFiles = Get-ChildItem $PSScriptRoot/../../specs/*.ps1
$testResults = @()

#$non_existant_buildfile = '' | Select-Object -Property Name, FullName
#$non_existant_buildfile.Name = 'specifying_a_non_existant_buildfile_should_fail.ps1'
#$non_existant_buildfile.FullName = 'c:\specifying_a_non_existant_buildfile_should_fail.ps1'
#$buildFiles += $non_existant_buildfile

describe 'PSake specs' {

    function GetResult {
        param(
            [string]$FileName,
            [bool]$BuildSucceeded
        )

        $shouldSucceed = $null

        if ($FileName.EndsWith('_should_pass.ps1')) {
            $shouldSucceed = $true
        } elseif ($FileName.EndsWith('_should_fail.ps1')) {
            $shouldSucceed = $false
        } else {
            throw "Invalid specification syntax. Specs should end with _should_pass or _should_fail. $FileName"
        }

        if ($BuildSucceeded -eq $shouldSucceed) {
            'Passed'
        } else {
            'Failed'
        }
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
        $testResult = '' | Select-Object -Property Name, Result
        $testResult.Name = $buildFile.Name

        it "$($buildFile.BaseName)" {

            $psakeParams.BuildFile = $buildFile.FullName
            Invoke-psake @psakeParams | Out-Null

            $testResult.Result = GetResult -FileName $buildFile.Name -BuildSucceeded $psake.build_success
            $testResult.Result | Should -Be 'Passed'
        }
    }
}


