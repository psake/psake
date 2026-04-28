function Get-PSakeScriptTasks {
    <#
    .SYNOPSIS
    Returns meta data about all the tasks defined in the provided psake script.

    .DESCRIPTION
    Loads the build file and evaluates task definitions without executing
    any tasks. Useful for tooling, IDE integrations, and tab completion.

    .PARAMETER BuildFile
    The path to the psake build script to read the tasks from.

    .EXAMPLE
    Get-PSakeScriptTasks -BuildFile '.\build.ps1'

    DependsOn        Alias Name    Description
    ---------        ----- ----    -----------
    {}                     Compile
    {}                     Clean
    {Test}                 Default
    {Clean, Compile}       Test

    Gets the psake tasks contained in the 'build.ps1' file.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseSingularNouns', '')]
    [CmdletBinding()]
    param(
        [string]
        $BuildFile
    )

    if (-not $BuildFile) {
        $BuildFile = $psake.ConfigDefault.BuildFileName
    }

    Write-Debug "Get-PSakeScriptTasks: BuildFile='$BuildFile'"
    try {
        Invoke-InBuildFileScope -BuildFile $BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
            param($CurrentContext)
            return Get-TasksFromContext -CurrentContext $CurrentContext
        }
    } finally {
        Restore-Environment
    }
}
