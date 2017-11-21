function LoadConfiguration {
    param(
        [string] $configdir = $PSScriptRoot
    )

    $psakeConfigFilePath = (join-path $configdir "psake-config.ps1")

    if (test-path $psakeConfigFilePath -pathType Leaf) {
        try {
            $config = GetCurrentConfigurationOrDefault
            . $psakeConfigFilePath
        } catch {
            throw "Error Loading Configuration from psake-config.ps1: " + $_
        }
    }
}
