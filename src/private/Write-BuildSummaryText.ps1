function Write-BuildSummaryText {
    [CmdletBinding()]
    param(
        [PsakeTask[]]$Tasks,
        [PsakeTask[]]$FailedTasks,
        [timespan]$Duration
    )

    $dash = "-" * 70

    # Build Summary header
    Write-PsakeOutput -Output ""
    Write-PsakeOutput -Output $dash
    Write-PsakeOutput -Output "Build Summary"
    Write-PsakeOutput -Output $dash

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
        Write-PsakeOutput -Output "Build SUCCEEDED" -OutputType 'Success'
    } else {
        Write-PsakeOutput -Output "Build FAILED" -OutputType 'Error'
    }

    # Error Summary section
    if ($FailedTasks.Count -gt 0) {
        Write-PsakeOutput -Output ""
        Write-PsakeOutput -Output $dash
        Write-PsakeOutput -Output "Error Summary"
        Write-PsakeOutput -Output $dash

        foreach ($task in $FailedTasks) {
            Write-PsakeOutput -Output "Task: $($task.Name)" -OutputType 'Error'
            if ($task.ErrorFormatted) {
                Write-PsakeOutput -Output $task.ErrorFormatted -OutputType 'Error'
            } elseif ($task.ErrorMessage) {
                Write-PsakeOutput -Output "Error: $($task.ErrorMessage)" -OutputType 'Error'
            }
            if ($task.Output) {
                Write-PsakeOutput -Output "--- Captured Output ---"
                $task.Output | ForEach-Object { Write-PsakeOutput -Output ($_.ToString()) }
            }
            Write-PsakeOutput -Output $dash
        }
    }
}
