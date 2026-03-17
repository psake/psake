function Write-BuildSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [timespan]$Duration,

        [Parameter(Mandatory = $true)]
        [string]$OutputView
    )

    if ($psake.Context.Count -eq 0) {
        Write-Debug "No psake context found. Exiting Write-BuildSummary."
        return
    }

    $currentContext = $psake.Context.Peek()

    # Collect executed tasks (same pattern as Write-TaskTimeSummary)
    $list = @()
    $tempStack = New-Object System.Collections.Stack
    while ($currentContext.executedTasks.Count -gt 0) {
        $taskKey = $currentContext.executedTasks.Pop()
        $tempStack.Push($taskKey)
        if ($taskKey -eq "default") { continue }
        $task = $currentContext.tasks.$taskKey
        $list += $task
    }
    # Restore the stack
    while ($tempStack.Count -gt 0) {
        $currentContext.executedTasks.Push($tempStack.Pop())
    }
    [Array]::Reverse($list)

    $failedTasks = @($list | Where-Object { -not $_.Success })

    if ($OutputView -eq 'JSON') {
        Write-BuildSummaryJson -Tasks $list -Duration $Duration
    } else {
        Write-BuildSummaryText -Tasks $list -FailedTasks $failedTasks -Duration $Duration
    }
}
