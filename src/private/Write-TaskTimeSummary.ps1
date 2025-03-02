function Write-TaskTimeSummary {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [timespan]
        $invokePsakeDuration
    )
    if ($psake.Context.count -eq 0) {
        Write-Debug "No psake context found. Exiting Write-TaskTimeSummary."
        return
    }

    $currentContext = $psake.Context.Peek()
    if ($currentContext.config.taskNameFormat -is [ScriptBlock]) {
        & $currentContext.config.taskNameFormat "Build Time Report"
    } elseif ($currentContext.config.taskNameFormat -ne "Executing {0}") {
        $currentContext.config.taskNameFormat -f "Build Time Report"
    } else {
        Write-PsakeOutput ("-" * 70)
        Write-PsakeOutput "Build Time Report"
        Write-PsakeOutput ("-" * 70)
    }

    $list = @()
    while ($currentContext.executedTasks.Count -gt 0) {
        $taskKey = $currentContext.executedTasks.Pop()
        $task = $currentContext.tasks.$taskKey
        if ($taskKey -eq "default") {
            continue
        }
        $list += New-Object PSObject -Property @{
            Name     = $task.Name
            Duration = $task.Duration.ToString("hh\:mm\:ss\.fff")
        }
    }
    [Array]::Reverse($list)
    $list += New-Object PSObject -Property @{
        Name     = "Total:"
        Duration = $invokePsakeDuration.ToString("hh\:mm\:ss\.fff")
    }
    # using "out-string | where-object" to filter out the blank line that format-table prepends
    $list | Format-Table -AutoSize -Property Name, Duration | Out-String -Stream | Where-Object { $_ } | Write-PsakeOutput
}
