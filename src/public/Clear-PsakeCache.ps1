function Clear-PsakeCache {
    <#
    .SYNOPSIS
    Clears the psake build cache.

    .DESCRIPTION
    Removes cached task state from the .psake/cache/ directory.
    This forces all tasks to re-execute on the next build.

    .PARAMETER Path
    The directory containing the .psake/cache/ folder. Defaults to the current
    directory.

    .PARAMETER TaskName
    Optional: clear cache for a specific task only.

    .EXAMPLE
    Clear-PsakeCache

    Clears all cached task state in the current directory.

    .EXAMPLE
    Clear-PsakeCache -TaskName 'Build'

    Clears cached state for the 'Build' task only.

    .LINK
    Invoke-psake
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Path = '.',

        [Parameter(Position = 1)]
        [string]$TaskName
    )

    Write-Debug "Clear-PsakeCache: task='$TaskName'"
    Write-Debug "Clear-PsakeCache: path='$resolvedPath'"
    $resolvedPath = Resolve-Path $Path
    Write-Debug "Clear-PsakeCache: resolvedPath='$resolvedPath'"
    $psakeDir = Join-Path $resolvedPath '.psake'
    $cacheDir = Join-Path $psakeDir 'cache'
    Write-Debug "Clear-PsakeCache: cacheDir='$cacheDir'"
    Clear-TaskCache -CacheDir $cacheDir -TaskName $TaskName
}
