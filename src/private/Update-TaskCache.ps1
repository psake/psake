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

    Write-Debug "Updating cache for task '$($Task.Name)'"
    if ($null -eq $Task.Inputs) {
        return
    }

    # Ensure cache directory exists
    if (-not (Test-Path $Plan.CacheDir)) {
        $null = New-Item -Path $Plan.CacheDir -ItemType Directory -Force
    }

    $inputHash = if ($Task.InputHash) { $Task.InputHash } else { Get-InputHash -Task $Task -Plan $Plan }
    $Plan.InputHashes[$Task.Name.ToLower()] = $inputHash

    $inputFiles = Resolve-TaskFiles -FileSpec $Task.Inputs
    $outputFiles = Resolve-TaskFiles -FileSpec $Task.Outputs

    $cacheEntry = @{
        TaskName    = $Task.Name
        InputHash   = $inputHash
        Timestamp   = [datetime]::UtcNow.ToString('o')
        InputFiles  = $inputFiles
        OutputFiles = $outputFiles
    }

    $cacheFile = Join-Path $Plan.CacheDir "$($Task.Name.ToLower()).json"
    $cacheEntry | ConvertTo-Json -Depth 3 | Set-Content -Path $cacheFile -Encoding UTF8
    Write-Debug "Cache written to '$cacheFile' with hash '$inputHash'"
}
