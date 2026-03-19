function Update-TaskCache {
    <#
    .SYNOPSIS
    Writes a cache entry after successful task execution.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PsakeTask]$Task,

        [Parameter(Mandatory = $true)]
        [PsakeBuildPlan]$Plan
    )

    if (-not $Task.Inputs -or $Task.Inputs.Count -eq 0) {
        return
    }

    # Ensure cache directory exists
    if (-not (Test-Path $Plan.CacheDir)) {
        $null = New-Item -Path $Plan.CacheDir -ItemType Directory -Force
    }

    $inputHash = if ($Task.InputHash) { $Task.InputHash } else { Get-InputHash -Task $Task -Plan $Plan }
    $Plan.InputHashes[$Task.Name.ToLower()] = $inputHash

    # Resolve input/output files for the cache record
    $inputFiles = @()
    foreach ($pattern in $Task.Inputs) {
        $resolved = @(Resolve-Path $pattern -ErrorAction SilentlyContinue)
        $inputFiles += $resolved | ForEach-Object { $_.Path }
    }

    $outputFiles = @()
    if ($Task.Outputs -and $Task.Outputs.Count -gt 0) {
        foreach ($pattern in $Task.Outputs) {
            $resolved = @(Resolve-Path $pattern -ErrorAction SilentlyContinue)
            $outputFiles += $resolved | ForEach-Object { $_.Path }
        }
    }

    $cacheEntry = @{
        TaskName    = $Task.Name
        InputHash   = $inputHash
        Timestamp   = [datetime]::UtcNow.ToString('o')
        InputFiles  = $inputFiles
        OutputFiles = $outputFiles
    }

    $cacheFile = Join-Path $Plan.CacheDir "$($Task.Name.ToLower()).json"
    $cacheEntry | ConvertTo-Json -Depth 3 | Set-Content -Path $cacheFile -Encoding UTF8
}
