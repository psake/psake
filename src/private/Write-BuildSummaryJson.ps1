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
            status   = if ($task.Success -and $task.Executed) { "Passed" } elseif (-not $task.Success -and $task.Executed) { "Failed" } else { "Not Executed" }
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
        success   = $psake.build_success
        duration  = $Duration.ToString("hh\:mm\:ss\.fff")
        buildFile = if ($psake.build_script_file) { $psake.build_script_file.Name } else { $null }
        tasks     = $taskData
    }

    if (-not $psake.build_success -and $psake.error_message) {
        $summary.error = $psake.error_message
    }

    $json = ConvertTo-Json -InputObject $summary -Depth 3
    # This is one of the few times Write-Output would be appropriate in a psake script, since we're outputting structured data that may be consumed by other tools. In this case, we'll write the JSON string to standard output so it can be captured or redirected as needed.
    Write-Output $json
}
