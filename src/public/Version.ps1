function Version {
    <#
    .SYNOPSIS
    Declares the required psake version for the build script.

    .DESCRIPTION
    Use this function at the top of a psake build script to declare which
    major version of psake the script requires. The compile phase will validate
    that the running psake version matches.

    .PARAMETER RequiredVersion
    The major version number required (e.g. 5).

    .EXAMPLE
    Version 5

    Declares that this build script requires psake v5.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$RequiredVersion
    )

    Write-Debug "Version declaration: requiring psake v$RequiredVersion"
    $currentContext = $psake.Context.Peek()
    $currentContext.requiredVersion = $RequiredVersion
}
