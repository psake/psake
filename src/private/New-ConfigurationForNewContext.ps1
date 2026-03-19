function New-ConfigurationForNewContext {
    [CmdletBinding()]
    param(
        [string] $BuildFile,
        [string] $Framework
    )

    $previousConfig = Get-CurrentConfigurationOrDefault

    $config = New-Object -TypeName 'PSObject' -Property @{
        buildFileName  = $previousConfig.buildFileName
        framework      = $previousConfig.framework
        taskNameFormat = $previousConfig.taskNameFormat
        verboseError   = $previousConfig.verboseError
        modules        = $previousConfig.modules
        moduleScope    = $previousConfig.moduleScope
    }

    if ($Framework) {
        $config.framework = $Framework
    }

    if ($BuildFile) {
        $config.buildFileName = $BuildFile
    }

    return $config
}
