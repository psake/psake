# Attempt to find the default build file given the config_default of
# buildFileName and legacyBuildFileName.  If neither exist optionally
# return the buildFileName or $null
function Get-DefaultBuildFile {
    param(
        [boolean] $UseDefaultIfNoneExist = $true
    )

    if (Test-Path $psake.ConfigDefault.buildFileName -PathType Leaf) {
        Write-Output $psake.ConfigDefault.buildFileName
    } elseif (Test-Path $psake.ConfigDefault.legacyBuildFileName -PathType Leaf) {
        Write-Warning "The default configuration file of default.ps1 is deprecated.  Please use psakefile.ps1"
        Write-Output $psake.ConfigDefault.legacyBuildFileName
    } elseif ($UseDefaultIfNoneExist) {
        Write-Output $psake.ConfigDefault.buildFileName
    }
}
