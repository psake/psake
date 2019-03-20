function Invoke-Task {
    <#
        .SYNOPSIS
        Executes another task in the current build script.

        .DESCRIPTION
        This is a function that will allow you to invoke a Task from within another Task in the current build script.

        .PARAMETER taskName
        The name of the task to execute.

        .EXAMPLE
        Invoke-Task "Compile"

        This example calls the "Compile" task.

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
        Invoke-psake
        .LINK
        Properties
        .LINK
        Task
        .LINK
        TaskSetup
        .LINK
        TaskTearDown
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$taskName
    )

    Assert $taskName ($msgs.error_invalid_task_name)

    $taskKey = $taskName.ToLower()

    $currentContext = $psake.context.Peek()

    if ($currentContext.aliases.Contains($taskKey)) {
        $taskName = $currentContext.aliases.$taskKey.Name
        $taskKey = $taskName.ToLower()
    }

    Assert ($currentContext.tasks.Contains($taskKey)) ($msgs.error_task_name_does_not_exist -f $taskName)

    if ($currentContext.executedTasks.Contains($taskKey))  { return }

    Assert (!$currentContext.callStack.Contains($taskKey)) ($msgs.error_circular_reference -f $taskName)

    $currentContext.callStack.Push($taskKey)

    $task = $currentContext.tasks.$taskKey

    $precondition_is_valid = & $task.Precondition

    if (!$precondition_is_valid) {
        WriteColoredOutput ($msgs.precondition_was_false -f $taskName) -foregroundcolor Cyan
    } else {
        if ($taskKey -ne 'default') {

            if ($task.PreAction -or $task.PostAction) {
                Assert ($null -ne $task.Action) ($msgs.error_missing_action_parameter -f $taskName)
            }

            if ($task.Action) {

                $stopwatch = new-object System.Diagnostics.Stopwatch

                try {
                    foreach($childTask in $task.DependsOn) {
                        Invoke-Task $childTask
                    }
                    $stopwatch.Start()

                    $currentContext.currentTaskName = $taskName

                    try {
                        & $currentContext.taskSetupScriptBlock @($task)
                        try {
                            if ($task.PreAction) {
                                & $task.PreAction
                            }

                            if ($currentContext.config.taskNameFormat -is [ScriptBlock]) {
                                $taskHeader = & $currentContext.config.taskNameFormat $taskName
                            } else {
                                $taskHeader = $currentContext.config.taskNameFormat -f $taskName
                            }
                            WriteColoredOutput $taskHeader -foregroundcolor Cyan

                            foreach ($variable in $task.requiredVariables) {
                                Assert ((Test-Path "variable:$variable") -and ($null -ne (Get-Variable $variable).Value)) ($msgs.required_variable_not_set -f $variable, $taskName)
                            }

                            & $task.Action
                        } finally {
                            if ($task.PostAction) {
                                & $task.PostAction
                            }
                        }
                    } catch {
                        # want to catch errors here _before_ we invoke TaskTearDown
                        # so that TaskTearDown reliably gets the Task-scoped
                        # success/fail/error context.

                        $currentConfig = GetCurrentConfigurationOrDefault
                        if ($currentConfig.verboseError) {
                            $error_message = "{0}: An Error Occurred. See Error Details Below: $($script:nl)" -f (Get-Date)
                            $error_message += ("-" * 70) + $script:nl
                            $error_message += "Error: {0}$($script:nl)" -f (ResolveError $_ -Short)
                            $error_message += ("-" * 70) + $script:nl
                            $error_message += ResolveError $_
                            $error_message += ("-" * 70) + $script:nl
                            $error_message += "Script Variables" + $script:nl
                            $error_message += ("-" * 70) + $script:nl
                            $error_message += get-variable -scope script | format-table | out-string
                        } else {
                            # ($_ | Out-String) gets error messages with source information included.
                            $error_message = "Error: {0}: $($script:nl){1}" -f (Get-Date), (ResolveError $_ -Short)
                        }

                        $task.Success        = $false
                        $task.ErrorMessage   = $_
                        $task.ErrorDetail    = $_ | Out-String
                        $task.ErrorFormatted = $error_message

                        throw $_ # pass this up the chain; don't have to cleanup here
                    } finally {
                        & $currentContext.taskTearDownScriptBlock $task
                    }
                } catch {
                    if ($task.ContinueOnError) {
                        "-"*70
                        WriteColoredOutput ($msgs.continue_on_error -f $taskName,$_) -foregroundcolor Yellow
                        "-"*70
                        [void]$currentContext.callStack.Pop()
                    }  else {
                        throw $_
                    }
                } finally {
                    $task.Duration = $stopwatch.Elapsed
                }
            } else {
                # no action was specified but we still execute all the dependencies
                foreach($childTask in $task.DependsOn) {
                    Invoke-Task $childTask
                }
            }
        } else {
            foreach($childTask in $task.DependsOn) {
                Invoke-Task $childTask
            }
        }

        Assert (& $task.Postcondition) ($msgs.postcondition_failed -f $taskName)
    }

    $poppedTaskKey = $currentContext.callStack.Pop()
    Assert ($poppedTaskKey -eq $taskKey) ($msgs.error_corrupt_callstack -f $taskKey,$poppedTaskKey)

    $currentContext.executedTasks.Push($taskKey)
}
