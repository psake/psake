function Get-PsakeBuildPlan {
    <#
    .SYNOPSIS
    Compiles a build file and returns the build plan without executing any tasks.

    .DESCRIPTION
    This is the primary testability API for psake v5. It loads a build file,
    validates the dependency graph, and returns a PsakeBuildPlan object that
    can be inspected in tests.

    .PARAMETER BuildFile
    The path to the psake build script. Defaults to 'psakefile.ps1'.

    .PARAMETER TaskList
    A list of task names to include in the plan. Defaults to 'default'.

    .EXAMPLE
    $plan = Get-PsakeBuildPlan -BuildFile './psakefile.ps1'
    $plan.Tasks | Should -HaveCount 4
    $plan.ExecutionOrder | Should -Be @('Clean', 'Compile', 'Test', 'Default')

    .EXAMPLE
    $plan = Get-PsakeBuildPlan
    $plan.TaskMap['build'].DependsOn | Should -Contain 'Clean'
    $plan.IsValid | Should -BeTrue

    .LINK
    Invoke-psake
    .LINK
    Test-PsakeTask
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

    try {
        $result = Invoke-psake -BuildFile $BuildFile -TaskList $TaskList -CompileOnly -NoLogo -Quiet
        return $result
    } finally {
        Restore-Environment
    }
}
