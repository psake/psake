function Get-PsakeBuildPlan {
    <#
    .SYNOPSIS
    Compiles a build file and returns the build plan without executing any tasks.

    .DESCRIPTION
    This is the primary testability API for psake v5. It loads a build file,
    validates the dependency graph, and returns a PsakeBuildPlan object that
    can be inspected in tests.

    This function always returns a [PsakeBuildPlan]. If the build file cannot
    be loaded or the dependency graph is invalid, an invalid plan is returned
    with IsValid = $false and ValidationErrors populated.

    The returned plan can be piped into Invoke-Psake for execution. Note that
    when piping, the build file is re-loaded during the execution phase to
    resolve properties, setup, and teardown blocks.

    .PARAMETER BuildFile
    The path to the psake build script. Defaults to 'psakefile.ps1'.

    .PARAMETER TaskList
    A list of task names to include in the plan. Defaults to 'default'.

    .EXAMPLE
    $plan = Get-PsakeBuildPlan -BuildFile './psakefile.ps1'
    $plan.Tasks | Should -HaveCount 4
    $plan.ExecutionOrder | Should -Be @('Clean', 'Compile', 'Test', 'Default')

    This example compiles the build file and asserts that there are 4 tasks and
    that the execution order is correct.

    .EXAMPLE
    $plan = Get-PsakeBuildPlan
    $plan.TaskMap['build'].DependsOn | Should -Contain 'Clean'
    $plan.IsValid | Should -BeTrue

    This example compiles the default build file and asserts that the 'build'
    task depends on the 'Clean' task and that the plan is valid.

    .EXAMPLE
    Get-PsakeBuildPlan -BuildFile './psakefile.ps1' | Invoke-Psake

    Compiles the build plan and pipes it into Invoke-Psake for execution.
    Note: the build file is re-loaded during the execution phase.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$BuildFile,

        [Parameter(Position = 1)]
        [string[]]$TaskList = @()
    )

    if (-not $BuildFile) {
        $BuildFile = $psake.ConfigDefault.BuildFileName
    }

    Write-Debug "Get-PsakeBuildPlan: BuildFile='$BuildFile' TaskList='$($TaskList -join ', ')'"

    try {
        Invoke-InBuildFileScope -BuildFile $BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
            param($CurrentContext, $Module)

            $effectiveTaskList = if ($TaskList -and $TaskList.Count -gt 0) {
                $TaskList
            } elseif ($CurrentContext.tasks.ContainsKey('default')) {
                @('default')
            } else {
                @()
            }

            $script:compiledPlan = Compile-BuildPlan -BuildFile $BuildFile -TaskList $effectiveTaskList
        }

        return $script:compiledPlan
    } catch {
        $invalidPlan = [PsakeBuildPlan]::new()
        $invalidPlan.BuildFile = $BuildFile
        $invalidPlan.IsValid = $false
        $invalidPlan.ValidationErrors = @($_.ToString())
        return $invalidPlan
    } finally {
        Restore-Environment
    }
}
