function Get-PSakeScriptTasks {
    <#
    .SYNOPSIS
    Returns meta data about all the tasks defined in the provided psake script.

    .DESCRIPTION
    Returns meta data about all the tasks defined in the provided psake script.

    .PARAMETER BuildFile
    The path to the psake build script to read the tasks from.

    .EXAMPLE
    PS C:\>Get-PSakeScriptTasks -BuildFile '.\build.ps1'

    DependsOn        Alias Name    Description
    ---------        ----- ----    -----------
    {}                     Compile
    {}                     Clean
    {Test}                 Default
    {Clean, Compile}       Test

    Gets the psake tasks contained in the 'build.ps1' file.

    .LINK
    Invoke-psake
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

    try {
        Invoke-InBuildFileScope -BuildFile $BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
            param($CurrentContext)
            return Get-TasksFromContext -CurrentContext $CurrentContext
        }
    } finally {
        Restore-Environment
    }
}
