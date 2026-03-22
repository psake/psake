function Get-DefaultBuildFile {
    [CmdletBinding()]
    param(
        [boolean] $UseDefaultIfNoneExist = $true
    )

    Write-Debug "Looking for default build file '$($psake.ConfigDefault.buildFileName)'"
    if (Test-Path $psake.ConfigDefault.buildFileName -PathType Leaf) {
        Write-Debug "Found build file '$($psake.ConfigDefault.buildFileName)'"
        Write-Output $psake.ConfigDefault.buildFileName
    } elseif ($UseDefaultIfNoneExist) {
        Write-Debug "Build file not found, using default '$($psake.ConfigDefault.buildFileName)'"
        Write-Output $psake.ConfigDefault.buildFileName
    } else {
        Write-Debug "Build file not found and UseDefaultIfNoneExist is false"
    }
}
