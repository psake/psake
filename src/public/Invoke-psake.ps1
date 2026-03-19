# spell-checker:ignore notr bitness
function Invoke-Psake {
    <#
    .SYNOPSIS
    Runs a psake build script.

    .DESCRIPTION
    This function runs a psake build script using a two-phase compile/run model.
    The compile phase loads the build file and validates the dependency graph.
    The run phase executes tasks in the resolved order.

    .PARAMETER BuildFile
    The path to the psake build script to execute

    .PARAMETER TaskList
    A comma-separated list of task names to execute

    .PARAMETER Framework
    The version of the .NET framework you want to use during build. You can append x86 or x64 to force a specific framework.
    If not specified, x86 or x64 will be detected based on the bitness of the PowerShell process.
    Possible values: '4.0', '4.0x86', '4.0x64', '4.5', '4.5x86', '4.5x64', '4.5.1', '4.5.1x86', '4.5.1x64', '4.6', '4.6.1', '4.6.2', '4.7', '4.7.1', '4.7.2', '4.8', '4.8.1'

    .PARAMETER Docs
    Prints a list of tasks and their descriptions

    .PARAMETER Parameters
    A hashtable containing parameters to be passed into the current build script.
    These parameters will be processed before the 'Properties' function of the script is processed.

    .PARAMETER Properties
    A hashtable containing properties to be passed into the current build script.
    These properties will override matching properties that are found in the 'Properties' function of the script.

    .PARAMETER Initialization
    A script block that will be executed before the tasks are executed.

    .PARAMETER NoLogo
    Do not display the startup banner and copyright message.

    .PARAMETER DetailedDocs
    Prints a more descriptive list of tasks and their descriptions.

    .PARAMETER NoTimeReport
    Do not display the time report.

    .PARAMETER OutputFormat
    The output format. 'Default' for console output, 'JSON' for JSON to stdout.

    .PARAMETER NoCache
    Bypass task caching. All tasks will execute regardless of cache state.

    .PARAMETER CompileOnly
    Return the build plan without executing any tasks. Useful for tooling and testing.

    .PARAMETER Quiet
    Suppress all console output. The PsakeBuildResult is still returned.

    .EXAMPLE
    Invoke-psake

    Runs the 'default' task in the 'psakefile.ps1' build script

    .EXAMPLE
    Invoke-psake '.\build.ps1' Tests,Package

    Runs the 'Tests' and 'Package' tasks in the 'build.ps1' build script

    .EXAMPLE
    Invoke-psake -CompileOnly

    Returns the build plan without executing any tasks.

    .EXAMPLE
    Invoke-psake -OutputFormat JSON

    Runs the build and outputs the result as JSON.

    .LINK
    Assert
    .LINK
    Exec
    .LINK
    FormatTaskName
    .LINK
    Framework
    .LINK
    Get-PSakeScriptTasks
    .LINK
    Include
    .LINK
    Properties
    .LINK
    Task
    .LINK
    TaskSetup
    .LINK
    TaskTearDown
    .LINK
    Properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$BuildFile,

        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]$TaskList = @(),

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Framework,

        [Parameter(Position = 3, Mandatory = $false)]
        [switch]$Docs = $false,

        [Parameter(Position = 4, Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Position = 5, Mandatory = $false)]
        [hashtable]$Properties = @{},

        [Parameter(Position = 6, Mandatory = $false)]
        [alias("init")]
        [scriptblock]$Initialization = {},

        [Parameter(Position = 7, Mandatory = $false)]
        [switch]$NoLogo,

        [Parameter(Position = 8, Mandatory = $false)]
        [switch]$DetailedDocs,

        [Parameter(Position = 9, Mandatory = $false)]
        [Alias("notr")]
        [switch]$NoTimeReport,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'JSON')]
        [string]$OutputFormat = 'Default',

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$CompileOnly,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet
    )

    # Note: $psake var is instantiated by the psake.psm1

    #region Store Script Variables
    $script:Framework = $Framework
    $script:Docs = $Docs
    $script:DetailedDocs = $DetailedDocs
    $script:Properties = $Properties
    $script:Initialization = $Initialization
    $script:Parameters = $Parameters
    $script:NoTimeReport = $NoTimeReport
    #endregion Store Script Variables

    $buildResult = $null

    try {
        if (-not $NoLogo -and -not $Quiet -and $OutputFormat -ne 'JSON') {
            "psake version {0}$($script:nl)Copyright (c) 2010-2018 James Kovacs & Contributors$($script:nl)" -f $psake.version
        }
        if (!$BuildFile) {
            $BuildFile = Get-DefaultBuildFile
        } elseif (
            !(Test-Path $BuildFile -PathType Leaf) -and
            ($null -ne (Get-DefaultBuildFile -UseDefaultIfNoneExist $false))
        ) {
            $TaskList = $BuildFile.Split(', ')
            $BuildFile = Get-DefaultBuildFile
        }

        $psake.error_message = $null

        # === COMPILE PHASE ===
        Invoke-InBuildFileScope -BuildFile $BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
            param($CurrentContext, $Module)

            if ($script:Docs -or $script:DetailedDocs) {
                if ($script:DetailedDocs) {
                    Write-Documentation -ShowDetailed:$true
                } else {
                    Write-Documentation
                }
                return
            }

            # Compile the build plan
            $effectiveTaskList = if ($TaskList -and $TaskList.Count -gt 0) {
                $TaskList
            } elseif ($CurrentContext.tasks.ContainsKey('default')) {
                @('default')
            } else {
                @()
            }

            $plan = Compile-BuildPlan -BuildFile $BuildFile -TaskList $effectiveTaskList

            if (-not $plan.IsValid) {
                throw ($plan.ValidationErrors -join "`n")
            }

            # If CompileOnly, store plan and return
            if ($CompileOnly) {
                $script:compiledPlan = $plan
                return
            }

            # === RUN PHASE ===
            $buildResult = Invoke-BuildPlan -Plan $plan `
                -NoCache:$NoCache `
                -Module $Module `
                -CurrentContext $CurrentContext `
                -Parameters $script:Parameters `
                -Properties $script:Properties `
                -Initialization $script:Initialization

            $script:buildResultOut = $buildResult

            if ($buildResult.Success) {
                $successMsg = $msgs.psake_success -f $BuildFile
                if (-not $Quiet -and $OutputFormat -ne 'JSON') {
                    Write-PsakeOutput ("$($script:nl)${successMsg}$($script:nl)") "success"
                }
            }

            if (-not $script:NoTimeReport -and -not $Quiet -and $OutputFormat -ne 'JSON') {
                Write-TaskTimeSummary $buildResult.Duration
            }
        }

        if ($CompileOnly) {
            $psake.build_success = $true
            return $script:compiledPlan
        }

        $buildResult = $script:buildResultOut
        $psake.build_success = $true

        if ($buildResult) {
            $buildResult.Success = $true
        }

    } catch {
        $psake.build_success = $false
        $psake.error_message = Format-ErrorMessage $_

        if ($buildResult) {
            $buildResult.Success = $false
            $buildResult.ErrorMessage = $psake.error_message
        } else {
            $buildResult = [PsakeBuildResult]::new()
            $buildResult.Success = $false
            $buildResult.BuildFile = $BuildFile
            $buildResult.ErrorMessage = $psake.error_message
            $buildResult.CompletedAt = [datetime]::UtcNow
        }

        $inNestedScope = ($psake.Context.count -gt 1)
        if ( $inNestedScope ) {
            throw $_
        } else {
            if (!$psake.run_by_psake_build_tester) {
                if (-not $Quiet -and $OutputFormat -ne 'JSON') {
                    Write-PsakeOutput $psake.error_message "error"
                }
            }
        }
    } finally {
        Restore-Environment
    }

    # Output
    if ($OutputFormat -eq 'JSON' -and $buildResult) {
        $buildResult | ConvertTo-Json -Depth 5
    }

    return $buildResult
}
