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

    Write-Debug "Testing cache for task '$($Task.Name)'"
    if ($null -eq $Task.Inputs) {
        Write-Debug "Task '$($Task.Name)' has no Inputs, skipping cache check"
        return $false
    }

    $cacheFile = Join-Path $Plan.CacheDir "$($Task.Name.ToLower()).json"
    if (-not (Test-Path $cacheFile)) {
        Write-Debug "No cache file found at '$cacheFile'"
        return $false
    }

    try {
        $cached = Get-Content $cacheFile -Raw | ConvertFrom-Json
    } catch {
        Write-Debug "Failed to read cache file: $_"
        return $false
    }

    $currentHash = Get-InputHash -Task $Task -Plan $Plan
    $Task.InputHash = $currentHash

    if ($cached.InputHash -ne $currentHash) {
        Write-Debug "Cache miss for task '$($Task.Name)': cached=$($cached.InputHash) current=$currentHash"
        return $false
    }

    # Verify outputs still exist
    if ($null -ne $Task.Outputs) {
        $outputFiles = Resolve-TaskFiles -FileSpec $Task.Outputs
        if ($outputFiles.Count -eq 0) {
            Write-Debug "Cache invalid for task '$($Task.Name)': output files missing"
            return $false
        }
    }

    Write-Debug "Cache hit for task '$($Task.Name)'"
    return $true
}
