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

    if ($null -eq $Task.Inputs) {
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
    if ($null -ne $Task.Outputs) {
        $outputFiles = Resolve-TaskFiles -FileSpec $Task.Outputs
        if ($outputFiles.Count -eq 0) {
            return $false
        }
    }

    return $true
}
