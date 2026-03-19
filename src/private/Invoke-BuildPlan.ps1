function Invoke-BuildPlan {
    <#
    .SYNOPSIS
    Executes a compiled build plan.

    .DESCRIPTION
    Takes a PsakeBuildPlan and executes tasks in the pre-computed order,
    with caching, setup/teardown hooks, and structured result collection.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PsakeBuildPlan]$Plan,

        [switch]$NoCache,

        [Parameter(Mandatory = $true)]
        $Module,

        [Parameter(Mandatory = $true)]
        $CurrentContext,

        [hashtable]$Parameters = @{},

        [hashtable]$Properties = @{},

        [scriptblock]$Initialization = {}
    )

    $buildResult = [PsakeBuildResult]::new()
    $buildResult.BuildFile = $Plan.BuildFile
    $buildResult.StartedAt = [datetime]::UtcNow
    $buildResult.Success = $true

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Inject parameters
        foreach ($key in $Parameters.Keys) {
            $variableSplat = @{
                Value   = $Parameters.$key
                WhatIf  = $false
                Confirm = $false
            }
            if (Test-Path "variable:\$key") {
                $null = Set-Variable @variableSplat -Name $key
            } else {
                $null = New-Item @variableSplat -Path "variable:\$key"
            }
        }

        # Execute property blocks
        while ($CurrentContext.properties.Count -gt 0) {
            $propertyBlock = $CurrentContext.properties.Pop()
            . $propertyBlock
        }

        # Inject command-line properties (override)
        foreach ($key in $Properties.Keys) {
            if (Test-Path "variable:\$key") {
                $null = Set-Variable -Name $key -Value $Properties.$key -WhatIf:$false -Confirm:$false
            }
        }

        # Run initialization
        . $Module $Initialization

        # Run build setup
        & $CurrentContext.buildSetupScriptBlock

        try {
            # Execute tasks in plan order
            foreach ($taskKey in $Plan.ExecutionOrder) {
                $task = $Plan.TaskMap[$taskKey]
                $taskResult = [PsakeTaskResult]::new()
                $taskResult.Name = $task.Name

                if ($taskKey -eq 'default') {
                    $taskResult.Status = 'Skipped'
                    $taskResult.Duration = [System.TimeSpan]::Zero
                    $buildResult.Tasks += $taskResult
                    $CurrentContext.executedTasks.Push($taskKey)
                    continue
                }

                $precondition_is_valid = & $task.PreCondition
                if (-not $precondition_is_valid) {
                    Write-PsakeOutput ($msgs.precondition_was_false -f $task.Name) "heading"
                    $taskResult.Status = 'Skipped'
                    $taskResult.Duration = [System.TimeSpan]::Zero
                    $buildResult.Tasks += $taskResult
                    $CurrentContext.executedTasks.Push($taskKey)
                    continue
                }

                # Check cache
                if (-not $NoCache -and $task.Inputs -and $task.Inputs.Count -gt 0) {
                    if (Test-TaskCache -Task $task -Plan $Plan) {
                        $task.Cached = $true
                        $taskResult.Status = 'Cached'
                        $taskResult.Cached = $true
                        $taskResult.Duration = [System.TimeSpan]::Zero
                        $taskResult.InputHash = $task.InputHash
                        $buildResult.Tasks += $taskResult
                        $CurrentContext.executedTasks.Push($taskKey)
                        Write-PsakeOutput "Skipping task '$($task.Name)' (cached)" "heading"
                        continue
                    }
                }

                if ($task.PreAction -or $task.PostAction) {
                    Assert ($null -ne $task.Action) ($msgs.error_missing_action_parameter -f $task.Name)
                }

                foreach ($variable in $task.RequiredVariables) {
                    Assert ((Test-Path "variable:$variable") -and ($null -ne (Get-Variable $variable).Value)) ($msgs.required_variable_not_set -f $variable, $task.Name)
                }

                if ($task.Action) {
                    $taskStopwatch = [System.Diagnostics.Stopwatch]::new()

                    try {
                        $taskStopwatch.Start()
                        $CurrentContext.currentTaskName = $task.Name

                        try {
                            & $CurrentContext.taskSetupScriptBlock @($task)
                            try {
                                if ($task.PreAction) {
                                    & $task.PreAction
                                }

                                if ($CurrentContext.config.taskNameFormat -is [ScriptBlock]) {
                                    $taskHeader = & $CurrentContext.config.taskNameFormat $task.Name
                                } else {
                                    $taskHeader = $CurrentContext.config.taskNameFormat -f $task.Name
                                }
                                Write-PsakeOutput $taskHeader "heading"

                                & $task.Action
                            } finally {
                                if ($task.PostAction) {
                                    & $task.PostAction
                                }
                            }
                        } catch {
                            $task.Success = $false
                            $task.ErrorMessage = $_
                            $task.ErrorDetail = $_ | Out-String
                            $task.ErrorFormatted = Format-ErrorMessage $_
                            throw $_
                        } finally {
                            & $CurrentContext.taskTearDownScriptBlock $task
                        }
                    } catch {
                        if ($task.ContinueOnError) {
                            "-" * 70
                            Write-PsakeOutput ($msgs.continue_on_error -f $task.Name, $_) "warning"
                            "-" * 70
                            $taskResult.Status = 'Failed'
                            $taskResult.ErrorMessage = $_.ToString()
                        } else {
                            $taskResult.Status = 'Failed'
                            $taskResult.ErrorMessage = $_.ToString()
                            $task.Duration = $taskStopwatch.Elapsed
                            $taskResult.Duration = $task.Duration
                            $buildResult.Tasks += $taskResult
                            throw $_
                        }
                    } finally {
                        $task.Duration = $taskStopwatch.Elapsed
                    }

                    $task.Executed = $true
                    if ($taskResult.Status -ne 'Failed') {
                        $taskResult.Status = 'Executed'
                    }
                    $taskResult.Duration = $task.Duration

                    # Update cache after successful execution
                    if ($task.Inputs -and $task.Inputs.Count -gt 0 -and $task.Success) {
                        Update-TaskCache -Task $task -Plan $Plan
                    }
                } else {
                    $taskResult.Status = 'Skipped'
                    $taskResult.Duration = [System.TimeSpan]::Zero
                }

                Assert (& $task.PostCondition) ($msgs.postcondition_failed -f $task.Name)

                $CurrentContext.executedTasks.Push($taskKey)
                $buildResult.Tasks += $taskResult
            }
        } finally {
            & $CurrentContext.buildTearDownScriptBlock
        }

    } catch {
        $buildResult.Success = $false
        $buildResult.ErrorMessage = Format-ErrorMessage $_
        throw $_
    } finally {
        $stopwatch.Stop()
        $buildResult.Duration = $stopwatch.Elapsed
        $buildResult.CompletedAt = [datetime]::UtcNow
    }

    return $buildResult
}
