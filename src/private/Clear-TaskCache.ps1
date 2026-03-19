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

    if (-not (Test-Path $CacheDir)) {
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
