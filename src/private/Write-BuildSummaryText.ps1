function Write-BuildSummaryText {
    [CmdletBinding()]
    param(
        [PsakeTask[]]$Tasks,
        [PsakeTask[]]$FailedTasks,
        [timespan]$Duration
    )

    $dash = "-" * 70

    # Build Summary header
    Write-PsakeOutput -Output $dash -OutputType 'Heading'
    Write-PsakeOutput -Output "Build Summary" -OutputType 'Heading'
    Write-PsakeOutput -Output $dash -OutputType 'Heading'

    # Task table
    $summaryList = @()
    foreach ($task in $Tasks) {
        # Status: [ ] = not executed, [+] = success, [-] = failed
        if ($task.Executed -and $task.RecursiveSuccess($Tasks)) {
            $status = "[+]"
        } elseif ($task.Executed -and -not $task.RecursiveSuccess($Tasks)) {
            $status = "[-]"
        } else {
            $status = "[ ]"
        }
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
        Write-PsakeOutput -Output $dash -OutputType 'Heading'
        Write-PsakeOutput -Output "Error Summary" -OutputType 'Heading'
        Write-PsakeOutput -Output $dash -OutputType 'Heading'

        foreach ($task in $FailedTasks) {
            Write-PsakeOutput -Output "Task: $($task.Name)" -OutputType 'Error'
            if ($task.ErrorFormatted) {
                Write-PsakeOutput -Output $task.ErrorFormatted -OutputType 'Error'
            } elseif ($task.ErrorMessage) {
                Write-PsakeOutput -Output "Error: $($task.ErrorMessage)" -OutputType 'Error'
            }
            if ($task.Output) {
                Write-PsakeOutput -Output "--- Captured Output ---" -OutputType 'Error'
                $task.Output | ForEach-Object { Write-PsakeOutput -Output ($_.ToString()) -OutputType 'Error' }
            }
            Write-PsakeOutput -Output $dash -OutputType 'Heading'
        }
        Write-PsakeOutput -Output "See `$psake.error_record for full error record(s)." -OutputType 'Error'
    }
}
