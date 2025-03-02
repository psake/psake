function Invoke-InBuildFileScope {
    [CmdletBinding()]
    param(
        [string]
        $BuildFile,
        $Module,
        [scriptblock]
        $ScriptBlock
    )

    # Execute the build file to set up the tasks and defaults
    Assert (Test-Path $BuildFile -PathType Leaf) ($msgs.error_build_file_not_found -f $BuildFile)

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
            "config"                        = CreateConfigurationForNewContext $BuildFile $framework
        }
    )

    # Load in the psake configuration (or default)
    Import-PsakeConfiguration -ConfigurationDirectory $psake.build_script_dir

    Set-Location $psake.build_script_dir

    # Import any modules declared in the build script
    LoadModules

    $frameworkOldValue = $framework

    . $psake.build_script_file.FullName

    $currentContext = $psake.Context.Peek()

    if ($framework -ne $frameworkOldValue) {
        Write-PsakeOutput $msgs.warning_deprecated_framework_variable "warning"
        $currentContext.config.framework = $framework
    }

    Set-BuildEnvironment

    while ($currentContext.includes.Count -gt 0) {
        $includeFilename = $currentContext.includes.Dequeue()
        . $includeFilename
    }

    & $ScriptBlock $currentContext $Module
}
