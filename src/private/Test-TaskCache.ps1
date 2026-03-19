function Test-TaskCache {
    <#
    .SYNOPSIS
    Checks if a task can be skipped due to cache hit.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PsakeTask]$Task,

        [Parameter(Mandatory = $true)]
        [PsakeBuildPlan]$Plan
    )

    if (-not $Task.Inputs -or $Task.Inputs.Count -eq 0) {
        return $false
    }

    $cacheFile = Join-Path $Plan.CacheDir "$($Task.Name.ToLower()).json"
    if (-not (Test-Path $cacheFile)) {
        return $false
    }

    try {
        $cached = Get-Content $cacheFile -Raw | ConvertFrom-Json
    } catch {
        return $false
    }

    $currentHash = Get-InputHash -Task $Task -Plan $Plan
    $Task.InputHash = $currentHash

    if ($cached.InputHash -ne $currentHash) {
        return $false
    }

    # Verify outputs still exist
    if ($Task.Outputs -and $Task.Outputs.Count -gt 0) {
        foreach ($pattern in $Task.Outputs) {
            $resolved = @(Resolve-Path $pattern -ErrorAction SilentlyContinue)
            if ($resolved.Count -eq 0) {
                return $false
            }
        }
    }

    return $true
}
