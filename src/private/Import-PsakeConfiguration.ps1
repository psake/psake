function Import-PsakeConfiguration {
    <#
    .SYNOPSIS
    Load psake-config.ps1 file
    .DESCRIPTION
    Load psake-config.ps1 if present in the directory of the current build script.
    If that file doesn't exist, load the default psake-config.ps1 file from the module directory.
    .PARAMETER ConfigurationDirectory
    The directory to search for the psake-config.ps1 file.
    #>
    param(
        [string]
        $ConfigurationDirectory = (Split-Path -Path $PSScriptRoot -Parent)
    )

    $configFilePath = Join-Path -Path $ConfigurationDirectory -ChildPath $psakeConfigFile
    $defaultConfigFilePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath $psakeConfigFile

    if (Test-Path -LiteralPath $configFilePath -PathType Leaf) {
        $configFileToLoad = $configFilePath
    } elseIf (Test-Path -LiteralPath $defaultConfigFilePath -PathType Leaf) {
        $configFileToLoad = $defaultConfigFilePath
    } else {
        throw 'Cannot find psake-config.ps1'
    }

    try {
        $config = Get-CurrentConfigurationOrDefault
        . $configFileToLoad
    } catch {
        throw 'Error Loading Configuration from {0}: {1}' -f $configFileToLoad, $_
    }
}
