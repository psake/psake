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

    Write-Debug "Executing build plan for '$($Plan.BuildFile)' with $($Plan.ExecutionOrder.Count) tasks"
    Write-Debug "Execution order: $($Plan.ExecutionOrder -join ' -> ')"
    Write-Debug "NoCache=$NoCache"

    # Build reverse-dependency map: taskKey -> list of taskKeys that directly depend on it
    $parentMap = @{}
    foreach ($taskKey in $Plan.ExecutionOrder) {
        if (-not $parentMap.ContainsKey($taskKey)) { $parentMap[$taskKey] = @() }
        $task = $Plan.TaskMap[$taskKey]
        foreach ($dep in $task.DependsOn) {
            $depKey = $dep.ToLower()
            if (-not $parentMap.ContainsKey($depKey)) { $parentMap[$depKey] = @() }
            $parentMap[$depKey] += $taskKey
        }
    }

    $failedTasks = @{}

    $buildResult = [PsakeBuildResult]::new()
    $buildResult.BuildFile = $Plan.BuildFile
    $buildResult.StartedAt = [datetime]::UtcNow
    $buildResult.Success = $true

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # In JSON and Quiet modes all task output is suppressed; in all other modes
    # output is routed directly to the host so it does not pollute the pipeline
    # (the return value of Invoke-BuildPlan must be a PsakeBuildResult only).
    $suppressOutput = $script:CurrentOutputFormat -in @('JSON', 'Quiet')

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
            $null = . $propertyBlock
        }

        # Inject command-line properties (override)
        foreach ($key in $Properties.Keys) {
            if (Test-Path "variable:\$key") {
                $null = Set-Variable -Name $key -Value $Properties.$key -WhatIf:$false -Confirm:$false
            }
        }

        # Run initialization
        $null = . $Module $Initialization

        # Run build setup
        if ($suppressOutput) { $null = & $CurrentContext.buildSetupScriptBlock } else { & $CurrentContext.buildSetupScriptBlock }

        try {
            # Execute tasks in plan order
            foreach ($taskKey in $Plan.ExecutionOrder) {
                $task = $Plan.TaskMap[$taskKey]
                $taskResult = [PsakeTaskResult]::new()
                $taskResult.Name = $task.Name

                Write-Debug "Processing task '$taskKey'"

                # Check if any dependency failed
                $failedDep = $task.DependsOn | Where-Object { $failedTasks.ContainsKey($_.ToLower()) } | Select-Object -First 1
                if ($failedDep) {
                    if ($task.ContinueOnError) {
                        # Failure absorbed — do not propagate to this task's own dependents
                        Write-BuildMessage ("-" * 70)
                        Write-BuildMessage ($msgs.continue_on_error -f $task.Name, "dependency '$failedDep' failed") "warning"
                        Write-BuildMessage ("-" * 70)
                        $taskResult.Status = 'Skipped'
                        $taskResult.Duration = [System.TimeSpan]::Zero
                        $buildResult.Tasks += $taskResult
                        $CurrentContext.executedTasks.Push($taskKey)
                        continue
                    } else {
                        throw "Task '$($task.Name)' cannot run because dependency '$failedDep' failed."
                    }
                }

                if ($taskKey -eq 'default') {
                    $taskResult.Status = 'Skipped'
                    $taskResult.Duration = [System.TimeSpan]::Zero
                    $buildResult.Tasks += $taskResult
                    $CurrentContext.executedTasks.Push($taskKey)
                    continue
                }

                $precondition_is_valid = & $task.PreCondition
                if (-not $precondition_is_valid) {
                    Write-BuildMessage ($msgs.precondition_was_false -f $task.Name) "heading"
                    $taskResult.Status = 'Skipped'
                    $taskResult.Duration = [System.TimeSpan]::Zero
                    $buildResult.Tasks += $taskResult
                    $CurrentContext.executedTasks.Push($taskKey)
                    continue
                }

                # Check cache for tasks with inputs (cache miss does not
                # necessarily mean the task will be executed, as preconditions
                # may still prevent execution)
                if (-not $NoCache -and $null -ne $task.Inputs) {
                    if (Test-TaskCache -Task $task -Plan $Plan) {
                        $task.Cached = $true
                        $taskResult.Status = 'Cached'
                        $taskResult.Cached = $true
                        $taskResult.Duration = [System.TimeSpan]::Zero
                        $taskResult.InputHash = $task.InputHash
                        $buildResult.Tasks += $taskResult
                        $CurrentContext.executedTasks.Push($taskKey)
                        Write-BuildMessage ($msgs.task_cached -f $task.Name) "heading"
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
                            if ($suppressOutput) { $null = & $CurrentContext.taskSetupScriptBlock @($task) } else { & $CurrentContext.taskSetupScriptBlock @($task) }
                            try {
                                if ($task.PreAction) {
                                    if ($suppressOutput) { $null = & $task.PreAction } else { & $task.PreAction }
                                }

                                if ($CurrentContext.config.taskNameFormat -is [ScriptBlock]) {
                                    $taskHeader = & $CurrentContext.config.taskNameFormat $task.Name
                                } else {
                                    $taskHeader = $CurrentContext.config.taskNameFormat -f $task.Name
                                }
                                Write-BuildMessage $taskHeader "heading"

                                if ($suppressOutput) { $null = & $task.Action } else { & $task.Action }
                            } finally {
                                if ($task.PostAction) {
                                    if ($suppressOutput) { $null = & $task.PostAction } else { & $task.PostAction }
                                }
                            }
                        } catch {
                            $task.Success = $false
                            $task.ErrorMessage = $_
                            $task.ErrorDetail = $_ | Out-String
                            $task.ErrorFormatted = Format-ErrorMessage $_
                            $task.ErrorRecord = $_
                            throw $_
                        } finally {
                            if ($suppressOutput) { $null = & $CurrentContext.taskTearDownScriptBlock $task } else { & $CurrentContext.taskTearDownScriptBlock $task }
                        }
                    } catch {
                        # Emit a positioned annotation so VS Code's problem matcher can
                        # populate the Problems panel with a clickable file:line entry.
                        # This fires for all task failure paths (absorbed or rethrown).
                        $annotationRecord = $_
                        if ($annotationRecord.InvocationInfo) {
                            $writeBuildAnnotationSplat = @{
                                Severity = 'error'
                                File     = $annotationRecord.InvocationInfo.ScriptName
                                Line     = $annotationRecord.InvocationInfo.ScriptLineNumber
                                Column   = $annotationRecord.InvocationInfo.OffsetInLine
                                Title    = $task.Name
                                Message  = $annotationRecord.Exception.Message
                            }
                            Write-BuildAnnotation @writeBuildAnnotationSplat
                        } else {
                            $writeBuildAnnotationSplat = @{
                                Severity = 'error'
                                Title    = $task.Name
                                Message  = $annotationRecord.Exception.Message
                            }
                            Write-BuildAnnotation @writeBuildAnnotationSplat
                        }

                        if ($task.ContinueOnError) {
                            # Failure absorbed — do not propagate to this task's own dependents
                            Write-BuildMessage ("-" * 70)
                            Write-BuildMessage ($msgs.continue_on_error -f $task.Name, $_) "warning"
                            Write-BuildMessage ("-" * 70)
                            $taskResult.Status = 'Failed'
                            $taskResult.ErrorMessage = $_.ToString()
                            $taskResult.ErrorRecord = $_
                        } else {
                            # Check if a direct parent has ContinueOnError — if so, this failure
                            # is absorbed by the parent (matches old recursive execution behaviour)
                            $absorbingParent = $parentMap[$taskKey] |
                                Where-Object { $Plan.TaskMap[$_].ContinueOnError } |
                                Select-Object -First 1
                            if ($absorbingParent) {
                                Write-BuildMessage ("-" * 70)
                                Write-BuildMessage ($msgs.continue_on_error -f $Plan.TaskMap[$absorbingParent].Name, $_) "warning"
                                Write-BuildMessage ("-" * 70)
                                $taskResult.Status = 'Failed'
                                $taskResult.ErrorMessage = $_.ToString()
                                $taskResult.ErrorRecord = $_
                                $failedTasks[$taskKey] = $true
                            } else {
                                $taskResult.Status = 'Failed'
                                $taskResult.ErrorMessage = $_.ToString()
                                $taskResult.ErrorRecord = $_
                                $task.Duration = $taskStopwatch.Elapsed
                                $taskResult.Duration = $task.Duration
                                $buildResult.Tasks += $taskResult
                                throw $_
                            }
                        }
                    } finally {
                        $task.Duration = $taskStopwatch.Elapsed
                    }


                    Write-Debug "Task '$($task.Name)' completed in $($task.Duration)"
                    $task.Executed = $true
                    if ($taskResult.Status -ne 'Failed') {
                        $taskResult.Status = 'Executed'
                    }
                    $taskResult.Duration = $task.Duration

                    # Update cache after successful execution
                    if ($null -ne $task.Inputs -and $task.Success) {
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
            if ($suppressOutput) { $null = & $CurrentContext.buildTearDownScriptBlock } else { & $CurrentContext.buildTearDownScriptBlock }
        }

    } catch {
        $buildResult.Success = $false
        $buildResult.ErrorMessage = Format-ErrorMessage $_
        $buildResult.ErrorRecord = $_
        throw $_
    } finally {
        $stopwatch.Stop()
        $buildResult.Duration = $stopwatch.Elapsed
        $buildResult.CompletedAt = [datetime]::UtcNow
        $script:buildResultOut = $buildResult
    }
}
