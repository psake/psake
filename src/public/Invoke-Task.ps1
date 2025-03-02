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
        [string]
        $TaskName
    )

    Assert $TaskName ($msgs.error_invalid_task_name)

    $taskKey = $TaskName.ToLower()

    $currentContext = $psake.Context.Peek()

    if ($currentContext.aliases.Contains($taskKey)) {
        $TaskName = $currentContext.aliases.$taskKey.Name
        $taskKey = $TaskName.ToLower()
    }

    Assert ($currentContext.tasks.Contains($taskKey)) ($msgs.error_task_name_does_not_exist -f $TaskName)

    if ($currentContext.executedTasks.Contains($taskKey)) { return }

    Assert (!$currentContext.callStack.Contains($taskKey)) ($msgs.error_circular_reference -f $TaskName)

    $currentContext.callStack.Push($taskKey)

    try {

        $task = $currentContext.tasks.$taskKey

        $precondition_is_valid = & $task.Precondition

        if (!$precondition_is_valid) {
            Write-PsakeOutput ($msgs.precondition_was_false -f $TaskName) "heading"
        } else {
            if ($taskKey -ne 'default') {

                if ($task.PreAction -or $task.PostAction) {
                    Assert ($null -ne $task.Action) ($msgs.error_missing_action_parameter -f $TaskName)
                }

                foreach ($variable in $task.requiredVariables) {
                    Assert ((Test-Path "variable:$variable") -and ($null -ne (Get-Variable $variable).Value)) ($msgs.required_variable_not_set -f $variable, $TaskName)
                }

                if ($task.Action) {

                    $stopwatch = New-Object System.Diagnostics.Stopwatch

                    try {
                        foreach ($childTask in $task.DependsOn) {
                            Invoke-Task $childTask
                        }
                        $stopwatch.Start()

                        $currentContext.currentTaskName = $TaskName

                        try {
                            & $currentContext.taskSetupScriptBlock @($task)
                            try {
                                if ($task.PreAction) {
                                    & $task.PreAction
                                }

                                if ($currentContext.config.taskNameFormat -is [ScriptBlock]) {
                                    $taskHeader = & $currentContext.config.taskNameFormat $TaskName
                                } else {
                                    $taskHeader = $currentContext.config.taskNameFormat -f $TaskName
                                }
                                Write-PsakeOutput $taskHeader "heading"

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
                            $task.Success = $false
                            $task.ErrorMessage = $_
                            $task.ErrorDetail = $_ | Out-String
                            $task.ErrorFormatted = Format-ErrorMessage $_



                            throw $_ # pass this up the chain; cleanup is handled higher int he stack
                        } finally {
                            & $currentContext.taskTearDownScriptBlock $task
                        }
                    } catch {
                        if ($task.ContinueOnError) {
                            "-" * 70
                            Write-PsakeOutput ($msgs.continue_on_error -f $TaskName, $_) "warning"
                            "-" * 70
                        } else {
                            throw $_
                        }
                    } finally {
                        $task.Duration = $stopwatch.Elapsed
                    }
                } else {
                    # no action was specified but we still execute all the dependencies
                    foreach ($childTask in $task.DependsOn) {
                        Invoke-Task $childTask
                    }
                }
            } else {
                foreach ($childTask in $task.DependsOn) {
                    Invoke-Task $childTask
                }
            }

            Assert (& $task.PostCondition) ($msgs.postcondition_failed -f $TaskName)
        }
    } catch {
        throw $_
    } finally {
        $poppedTaskKey = $currentContext.callStack.Pop()
        Assert ($poppedTaskKey -eq $taskKey) ($msgs.error_corrupt_callstack -f $taskKey, $poppedTaskKey)
    }

    $currentContext.executedTasks.Push($taskKey)
}
