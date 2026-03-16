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

function Write-BuildSummaryText {
    [CmdletBinding()]
    param(
        [PsakeTask[]]$Tasks,
        [PsakeTask[]]$FailedTasks,
        [timespan]$Duration
    )

    $dash = "-" * 70

    # Build Summary header
    Write-PsakeOutput ""
    Write-PsakeOutput $dash
    Write-PsakeOutput "Build Summary"
    Write-PsakeOutput $dash

    # Task table
    $summaryList = @()
    foreach ($task in $Tasks) {
        $status = if ($task.Success) { "[+]" } else { "[-]" }
        $summaryList += New-Object PSObject -Property @{
            Name     = $task.Name
            Status   = $status
            Duration = $task.Duration.ToString("hh\:mm\:ss\.fff")
        }
    }
    $summaryList += New-Object PSObject -Property @{
        Name     = "Total:"
        Status   = ""
        Duration = $Duration.ToString("hh\:mm\:ss\.fff")
    }
    $summaryList | Format-Table -AutoSize -Property Name, Status, Duration |
        Out-String -Stream | Where-Object { $_ } | Write-PsakeOutput

    # Result line
    if ($psake.build_success) {
        Write-PsakeOutput "Build SUCCEEDED" "success"
    } else {
        Write-PsakeOutput "Build FAILED" "error"
    }

    # Error Summary section
    if ($FailedTasks.Count -gt 0) {
        Write-PsakeOutput ""
        Write-PsakeOutput $dash
        Write-PsakeOutput "Error Summary"
        Write-PsakeOutput $dash

        foreach ($task in $FailedTasks) {
            Write-PsakeOutput "Task: $($task.Name)" "error"
            if ($task.ErrorFormatted) {
                Write-PsakeOutput $task.ErrorFormatted "error"
            } elseif ($task.ErrorMessage) {
                Write-PsakeOutput "Error: $($task.ErrorMessage)" "error"
            }
            if ($task.Output) {
                Write-PsakeOutput "--- Captured Output ---"
                $task.Output | ForEach-Object { Write-PsakeOutput ($_.ToString()) }
            }
            Write-PsakeOutput $dash
        }
    }
}

function Write-BuildSummaryJson {
    [CmdletBinding()]
    param(
        [PsakeTask[]]$Tasks,
        [timespan]$Duration
    )

    $taskData = @()
    foreach ($task in $Tasks) {
        $entry = [ordered]@{
            name     = $task.Name
            status   = if ($task.Success) { "Passed" } else { "Failed" }
            duration = $task.Duration.ToString("hh\:mm\:ss\.fff")
        }
        if (-not $task.Success) {
            if ($task.ErrorMessage) {
                $entry.error = $task.ErrorMessage.ToString()
            }
            if ($task.Output) {
                $entry.output = @($task.Output | ForEach-Object { $_.ToString() })
            }
        }
        $taskData += $entry
    }

    $summary = [ordered]@{
        result    = if ($psake.build_success) { "SUCCEEDED" } else { "FAILED" }
        duration  = $Duration.ToString("hh\:mm\:ss\.fff")
        buildFile = if ($psake.build_script_file) { $psake.build_script_file.Name } else { $null }
        tasks     = $taskData
    }

    if (-not $psake.build_success -and $psake.error_message) {
        $summary.error = $psake.error_message
    }

    $json = ConvertTo-Json -InputObject $summary -Depth 3
    Write-PsakeOutput $json
}
