function New-ConfigurationForNewContext {
    [CmdletBinding()]
    param(
        [string] $BuildFile,
        [string] $Framework
    )

    Write-Debug "Creating new configuration context (BuildFile='$BuildFile', Framework='$Framework')"
    $previousConfig = Get-CurrentConfigurationOrDefault

    $config = New-Object -TypeName 'PSObject' -Property @{
        buildFileName        = $previousConfig.buildFileName
        framework            = $previousConfig.framework
        frameworkIsExplicit  = $false
        taskNameFormat       = $previousConfig.taskNameFormat
        verboseError         = $previousConfig.verboseError
        modules              = $previousConfig.modules
        moduleScope          = $previousConfig.moduleScope
    }

    if ($Framework) {
        $config.framework = $Framework
        $config.frameworkIsExplicit = $true
    }

    if ($BuildFile) {
        $config.buildFileName = $BuildFile
    }

    return $config
}
