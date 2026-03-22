# spell-checker:ignore notr bitness
function Invoke-Psake {
    <#
    .SYNOPSIS
    Runs a psake build script.

    .DESCRIPTION
    This function runs a psake build script using a two-phase compile/run model.
    The compile phase loads the build file and validates the dependency graph.
    The run phase executes tasks in the resolved order.

    A pre-compiled [PsakeBuildPlan] from Get-PsakeBuildPlan can be piped in to
    skip the compile phase. When doing so, the build file is re-loaded for the
    execution phase to resolve properties, setup, and teardown blocks.

    .PARAMETER BuildFile
    The path to the psake build script to execute

    .PARAMETER TaskList
    A comma-separated list of task names to execute

    .PARAMETER Framework

    The version of the .NET framework you want to use during build. You can
    append x86 or x64 to force a specific framework. If not specified, x86 or
    x64 will be detected based on the bitness of the PowerShell process.
    Possible values: '4.0', '4.0x86', '4.0x64', '4.5', '4.5x86', '4.5x64',
    '4.5.1', '4.5.1x86', '4.5.1x64', '4.6', '4.6.1', '4.6.2', '4.7', '4.7.1',
    '4.7.2', '4.8', '4.8.1'

    .PARAMETER Docs
    Prints a list of tasks and their descriptions

    .PARAMETER Parameters
    A hashtable containing parameters to be passed into the current build
    script. These parameters will be processed before the 'Properties' function
    of the script is processed.

    .PARAMETER Properties
    A hashtable containing properties to be passed into the current build
    script. These properties will override matching properties that are found in
    the 'Properties' function of the script.

    .PARAMETER Initialization
    A script block that will be executed before the tasks are executed.

    .PARAMETER NoLogo
    Do not display the startup banner and copyright message.

    .PARAMETER DetailedDocs
    Prints a more descriptive list of tasks and their descriptions.

    .PARAMETER NoTimeReport
    Do not display the time report.

    .PARAMETER OutputFormat
    The output format. 'Default' for console output, 'JSON' for JSON to stdout,
    'GitHubActions' for GitHub Actions workflow annotations (::error::, ::warning::, ::debug::).

    .PARAMETER NoCache
    Bypass task caching. All tasks will execute regardless of cache state.

    .PARAMETER CompileOnly
    Return the build plan without executing any tasks. Delegates to
    Get-PsakeBuildPlan. Useful for tooling and testing.

    .PARAMETER Quiet
    Suppress all console output. The PsakeBuildResult is still returned.

    .PARAMETER BuildPlan
    A pre-compiled [PsakeBuildPlan] to execute, typically from Get-PsakeBuildPlan
    via the pipeline. Compile-phase parameters (BuildFile, TaskList, Framework,
    Docs, DetailedDocs, CompileOnly) are ignored when a plan is provided.
    Note: the build file is re-loaded during the execution phase.

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
    Get-PsakeBuildPlan | Invoke-Psake

    Compiles the build plan then executes it. The build file is re-loaded
    during the execution phase.

    .EXAMPLE
    Invoke-psake -OutputFormat JSON

    Runs the build and outputs the result as JSON.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $false)]
        [string]$BuildFile,

        [Parameter(Position = 1, Mandatory = $false)]
        [string[]]$TaskList = @('default'),

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
        [ValidateSet('Default', 'JSON', 'GitHubActions')]
        [string]$OutputFormat = 'Default',

        [Parameter(Mandatory = $false)]
        [switch]$NoCache,

        [Parameter(Mandatory = $false)]
        [switch]$CompileOnly,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet,

        [Parameter(ValueFromPipeline)]
        [PsakeBuildPlan]$BuildPlan
    )

    begin {
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

        # Set output format for Write-BuildMessage
        $script:CurrentOutputFormat = if ($Quiet) { 'Quiet' } else { $OutputFormat }

        Write-Debug "Invoke-Psake: BuildFile='$BuildFile' TaskList='$($TaskList -join ', ')' OutputFormat='$OutputFormat' NoCache=$NoCache CompileOnly=$CompileOnly Quiet=$Quiet"
    }

    process {
        # === COMPILE-ONLY: delegate to Get-PsakeBuildPlan ===
        # This is the inversion point: Invoke-Psake calls Get-PsakeBuildPlan,
        # not the other way around. Early return avoids the try/finally below
        # so Restore-Environment is handled entirely by Get-PsakeBuildPlan.
        if (-not $BuildPlan -and $CompileOnly) {
            if (!$BuildFile) {
                $BuildFile = Get-DefaultBuildFile
            } elseif (
                !(Test-Path $BuildFile -PathType Leaf) -and
                ($null -ne (Get-DefaultBuildFile -UseDefaultIfNoneExist $false))
            ) {
                $TaskList = $BuildFile.Split(', ')
                $BuildFile = Get-DefaultBuildFile
            }

            $plan = Get-PsakeBuildPlan -BuildFile $BuildFile -TaskList $TaskList
            $psake.build_success = $plan.IsValid
            return $plan
        }

        $buildResult = $null
        $script:buildResultOut = $null

        try {
            if (-not $NoLogo -and -not $Quiet -and $OutputFormat -ne 'JSON') {
                Write-BuildMessage ((
                        ("psake version {0}" -f $psake.version),
                        "Copyright (c) 2010-2026 James Kovacs & Contributors"
                    ) -join $script:nl) "Heading"
            }

            $psake.error_message = $null

            if ($BuildPlan) {
                # === PIPELINE INPUT: Execute a pre-compiled plan ===
                # The build file is re-loaded here so that property blocks,
                # setup/teardown hooks, and includes are resolved in a fresh
                # execution context. Compile-phase parameters (BuildFile,
                # TaskList, Framework, Docs, DetailedDocs, CompileOnly) are
                # ignored because the plan is already compiled.
                Invoke-InBuildFileScope -BuildFile $BuildPlan.BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
                    param($CurrentContext, $Module)

                    $invokeBuildPlanSplat = @{
                        Plan           = $BuildPlan
                        NoCache        = $NoCache
                        Module         = $Module
                        CurrentContext = $CurrentContext
                        Parameters     = $script:Parameters
                        Properties     = $script:Properties
                        Initialization = $script:Initialization
                    }
                    $buildResult = Invoke-BuildPlan @invokeBuildPlanSplat
                    $script:buildResultOut = $buildResult

                    if ($buildResult.Success) {
                        $successMsg = $msgs.psake_success -f $BuildPlan.BuildFile
                        if (-not $Quiet -and $OutputFormat -ne 'JSON') {
                            Write-BuildMessage ("$($script:nl)${successMsg}$($script:nl)") "Success"
                        }
                    }

                    if (-not $script:NoTimeReport -and -not $Quiet -and $OutputFormat -ne 'JSON') {
                        Write-TaskTimeSummary $buildResult.Duration
                    }
                }

                $buildResult = $script:buildResultOut
                $psake.build_success = $true
                if ($buildResult) {
                    $buildResult.Success = $true
                }

            } else {
                # === STANDARD PATH: resolve build file, compile, and run ===
                if (!$BuildFile) {
                    $BuildFile = Get-DefaultBuildFile
                } elseif (
                    !(Test-Path $BuildFile -PathType Leaf) -and
                    ($null -ne (Get-DefaultBuildFile -UseDefaultIfNoneExist $false))
                ) {
                    $TaskList = $BuildFile.Split(', ')
                    $BuildFile = Get-DefaultBuildFile
                }

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

                    Write-Debug "Starting compile phase"
                    $plan = Compile-BuildPlan -BuildFile $BuildFile -TaskList $effectiveTaskList

                    if (-not $plan.IsValid) {
                        throw ($plan.ValidationErrors -join "`n")
                    }

                    Write-Debug "Compile phase complete, starting run phase"
                    # === RUN PHASE ===
                    $invokeBuildPlanSplat = @{
                        Plan           = $plan
                        NoCache        = $NoCache
                        Module         = $Module
                        CurrentContext = $CurrentContext
                        Parameters     = $script:Parameters
                        Properties     = $script:Properties
                        Initialization = $script:Initialization
                    }
                    $buildResult = Invoke-BuildPlan @invokeBuildPlanSplat

                    $script:buildResultOut = $buildResult

                    if ($buildResult.Success) {
                        $successMsg = $msgs.psake_success -f $BuildFile
                        if (-not $Quiet -and $OutputFormat -ne 'JSON') {
                            Write-BuildMessage ("$($script:nl)${successMsg}$($script:nl)") "Success"
                        }
                    }

                    if (-not $script:NoTimeReport -and -not $Quiet -and $OutputFormat -ne 'JSON') {
                        Write-TaskTimeSummary $buildResult.Duration
                    }
                }

                if ($Docs -or $DetailedDocs) {
                    $psake.build_success = $true
                    return
                }

                $buildResult = $script:buildResultOut
                $psake.build_success = $true

                if ($buildResult) {
                    $buildResult.Success = $true
                }
            }

        } catch {
            $psake.build_success = $false
            $psake.error_message = Format-ErrorMessage $_
            $psake.error_record = $_

            if ($buildResult) {
                Assert ($buildResult -is [PsakeBuildResult]) "Expected build result to be of type PsakeBuildResult. Is $($buildResult.GetType().FullName)"
                $buildResult.Success = $false
                $buildResult.ErrorMessage = $psake.error_message
                $buildResult.ErrorRecord = $_
            } else {
                $buildResult = [PsakeBuildResult]::new()
                $buildResult.Success = $false
                $buildResult.BuildFile = if ($BuildPlan) { $BuildPlan.BuildFile } else { $BuildFile }
                $buildResult.ErrorMessage = $psake.error_message
                $buildResult.CompletedAt = [datetime]::UtcNow
                $buildResult.ErrorRecord = $_
            }

            $inNestedScope = ($psake.Context.count -gt 1)
            if ( $inNestedScope ) {
                throw $_
            } else {
                if (!$psake.run_by_psake_build_tester) {
                    if (-not $Quiet -and $OutputFormat -ne 'JSON') {
                        Write-BuildMessage $psake.error_message "Error"
                    }
                }
            }
        } finally {
            Restore-Environment
        }

        # Output
        if ($OutputFormat -eq 'JSON' -and $buildResult) {
            $buildResult | ConvertTo-Json -Depth 3 -WarningAction Ignore
        } else {
            return $buildResult
        }
    }
}
