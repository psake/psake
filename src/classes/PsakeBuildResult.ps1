class PsakeTaskResult {
    [string]$Name
    [string]$Status        # 'Executed', 'Cached', 'Skipped', 'Failed'
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
    [datetime]$StartedAt
    [datetime]$CompletedAt
}
