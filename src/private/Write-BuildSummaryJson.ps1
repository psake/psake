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
    Write-PsakeOutput -Output $json
}
