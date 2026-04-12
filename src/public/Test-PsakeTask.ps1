function Test-PsakeTask {
    <#
    .SYNOPSIS
    Runs a single task's Action in isolation, without triggering dependencies.

    .DESCRIPTION
    Compiles the build file, finds the specified task, and executes only its
    Action scriptblock with the provided variables. Dependencies are NOT
    executed.This enables unit-testing individual tasks.

    .PARAMETER BuildFile
    The path to the psake build script. Defaults to 'psakefile.ps1'.

    .PARAMETER TaskName
    The name of the task to execute.

    .PARAMETER Variables
    A hashtable of variables to inject into the task's execution scope.

    .EXAMPLE
    $result = Test-PsakeTask -BuildFile './psakefile.ps1' -TaskName 'Build' -Variables @{
        Configuration = 'Debug'
        OutputDir = './test-output'
    }
    $result.Success | Should -BeTrue

    This example runs the 'Build' task from 'psakefile.ps1' with two variables
    injected into the task's scope. The result object contains details about the
    execution, including success status, duration, and any error messages.
    .NOTES
    This function is intended for testing purposes and does not execute task
    dependencies or pre/post actions. It directly invokes the specified task's
    Action scriptblock in isolation.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$BuildFile,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TaskName,

        [Parameter(Position = 2)]
        [hashtable]$Variables = @{}
    )

    if (-not $BuildFile) {
        $BuildFile = $psake.ConfigDefault.BuildFileName
    }

    Write-Debug "Test-PsakeTask: BuildFile='$BuildFile' TaskName='$TaskName' Variables=$($Variables.Count)"
    $result = [PsakeTaskResult]::new()
    $result.Name = $TaskName

    try {
        Invoke-InBuildFileScope -BuildFile $BuildFile -Module $MyInvocation.MyCommand.Module -ScriptBlock {
            param($CurrentContext, $Module)

            $taskKey = $TaskName.ToLower()

            # Resolve alias
            if ($CurrentContext.aliases.ContainsKey($taskKey)) {
                $taskKey = $CurrentContext.aliases[$taskKey].Name.ToLower()
            }

            Assert ($CurrentContext.tasks.ContainsKey($taskKey)) ($msgs.error_task_name_does_not_exist -f $TaskName)

            $task = $CurrentContext.tasks[$taskKey]

            # Inject variables
            foreach ($key in $Variables.Keys) {
                Set-Variable -Name $key -Value $Variables[$key] -WhatIf:$false -Confirm:$false
            }

            # Execute property blocks for context
            while ($CurrentContext.properties.Count -gt 0) {
                $propertyBlock = $CurrentContext.properties.Pop()
                . $propertyBlock
            }

            if ($task.Action) {
                $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    & $task.Action
                    $result.Status = 'Executed'
                } catch {
                    $result.Status = 'Failed'
                    $result.ErrorMessage = $_.ToString()
                    # Blanket rethrow: preserve the task's original ErrorRecord
                    # for the caller after recording the failure on $result.
                    throw $_
                } finally {
                    $stopwatch.Stop()
                    $result.Duration = $stopwatch.Elapsed
                }
            } else {
                $result.Status = 'Skipped'
            }
        }

        $psake.build_success = $true
    } catch {
        $psake.build_success = $false
        $result.Status = 'Failed'
        if (-not $result.ErrorMessage) {
            $result.ErrorMessage = $_.ToString()
        }
    } finally {
        Restore-Environment
    }

    return $result
}
