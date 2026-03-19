function Get-DefaultBuildFile {
    param(
        [boolean] $UseDefaultIfNoneExist = $true
    )

    if (Test-Path $psake.ConfigDefault.buildFileName -PathType Leaf) {
        Write-Output $psake.ConfigDefault.buildFileName
    } elseif ($UseDefaultIfNoneExist) {
        Write-Output $psake.ConfigDefault.buildFileName
    }
}
