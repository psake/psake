function Resolve-TaskFiles {
    <#
    .SYNOPSIS
    Resolves a task's Inputs or Outputs to a list of file paths.

    .DESCRIPTION
    Accepts either a string array of glob patterns or a scriptblock that returns
    file paths. Scriptblocks are evaluated at call time, enabling dynamic file
    resolution based on configuration, environment, or other runtime state.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        $FileSpec
    )

    if ($null -eq $FileSpec) {
        return @()
    }

    # Scriptblock: evaluate and collect results
    if ($FileSpec -is [scriptblock]) {
        $results = @(& $FileSpec)
        # Flatten — the scriptblock may return FileInfo objects, strings, or mixed
        return @($results | ForEach-Object {
            if ($_ -is [System.IO.FileInfo] -or $_ -is [System.IO.DirectoryInfo]) {
                $_.FullName
            } elseif ($_ -is [System.Management.Automation.PathInfo]) {
                $_.Path
            } else {
                [string]$_
            }
        })
    }

    # String or string array: resolve as glob patterns
    $patterns = @($FileSpec)
    $files = @()
    foreach ($pattern in $patterns) {
        $resolved = @(Resolve-Path $pattern -ErrorAction SilentlyContinue)
        $files += $resolved | ForEach-Object { $_.Path }
    }
    return $files
}
