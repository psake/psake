# spell-checker:ignore psmoduleinfo
function Invoke-InBuildFileScope {
    <#
    .SYNOPSIS
    Executes a script block in the context of a psake build file.

    .DESCRIPTION
    Executes a script block in the context of a psake build file.
    This function is used to execute the psake build file and set up the tasks
    and defaults.

    .PARAMETER BuildFile
    The path to the psake build script to execute.

    .PARAMETER Module
    The module that is calling this function.

    .PARAMETER ScriptBlock
    The script block to execute in the context of the build file.

    .EXAMPLE
    Invoke-InBuildFileScope -BuildFile '.\build.ps1' -Module $MyInvocation.MyCommand.Module -ScriptBlock { param($CurrentContext) $CurrentContext }

    Executes the build.ps1 file and returns the current context.
    #>
    [CmdletBinding()]
    param(
        [string]
        $BuildFile,
        [psmoduleinfo]
        $Module,
        [scriptblock]
        $ScriptBlock
    )

    # Execute the build file to set up the tasks and defaults
    Assert (Test-Path $BuildFile -PathType Leaf) ($msgs.error_build_file_not_found -f $BuildFile)

    # psake comes from the psake.psm1
    $psake.build_script_file = Get-Item $BuildFile
    $psake.build_script_dir = $psake.build_script_file.DirectoryName
    $psake.build_success = $false

    # Create a new psake context
    $psake.Context.push(
        @{
            "buildSetupScriptBlock"         = {}
            "buildTearDownScriptBlock"      = {}
            "taskSetupScriptBlock"          = {}
            "taskTearDownScriptBlock"       = {}
            "executedTasks"                 = New-Object System.Collections.Stack
            "callStack"                     = New-Object System.Collections.Stack
            "originalEnvPath"               = $env:PATH
            "originalDirectory"             = Get-Location
            "originalErrorActionPreference" = $global:ErrorActionPreference
            "tasks"                         = @{}
            "aliases"                       = @{}
            "properties"                    = New-Object System.Collections.Stack
            "includes"                      = New-Object System.Collections.Queue
            "config"                        = New-ConfigurationForNewContext -Build $BuildFile -Framework $script:Framework
        }
    )

    # Load in the psake configuration (or default)
    Import-PsakeConfiguration -ConfigurationDirectory $psake.build_script_dir

    Set-Location $psake.build_script_dir

    # Import any modules declared in the build script
    LoadModules

    $frameworkOldValue = $script:Framework

    . $psake.build_script_file.FullName

    $currentContext = $psake.Context.Peek()

    if ($script:Framework -ne $frameworkOldValue) {
        Write-PsakeOutput $msgs.warning_deprecated_framework_variable "warning"
        $currentContext.config.framework = $script:Framework
    }

    Set-BuildEnvironment

    while ($currentContext.includes.Count -gt 0) {
        $includeFilename = $currentContext.includes.Dequeue()
        . $includeFilename
    }

    & $ScriptBlock $currentContext $Module
}
