function Clear-TaskCache {
    <#
    .SYNOPSIS
    Clears the psake cache directory.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CacheDir,

        [string]$TaskName
    )

    Write-Debug "Clearing cache in '$CacheDir'$(if ($TaskName) { " for task '$TaskName'" })"
    if (-not (Test-Path $CacheDir)) {
        Write-Debug "Cache directory not found, nothing to clear"
        return
    }

    if ($TaskName) {
        $cacheFile = Join-Path $CacheDir "$($TaskName.ToLower()).json"
        if (Test-Path $cacheFile) {
            Remove-Item $cacheFile -Force
        }
    } else {
        Remove-Item (Join-Path $CacheDir '*') -Force -ErrorAction SilentlyContinue
    }
}
