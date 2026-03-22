class PsakeTaskResult {
    [string]$Name
    [TaskStatus]$Status # 'Executed', 'Cached', 'Skipped', 'Failed'
    [System.TimeSpan]$Duration
    [bool]$Cached
    [string]$ErrorMessage
    [string]$InputHash
}

class PsakeBuildResult {
    [bool]$Success
    [string]$BuildFile
    [System.TimeSpan]$Duration
    [PsakeTaskResult[]]$Tasks = @()
    [string]$ErrorMessage
    [System.Management.Automation.ErrorRecord[]]$ErrorRecord
    [datetime]$StartedAt
    [datetime]$CompletedAt
}
