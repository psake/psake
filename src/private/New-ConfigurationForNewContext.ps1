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
        coloredOutput  = $previousConfig.coloredOutput
        modules        = $previousConfig.modules
        moduleScope    = $previousConfig.moduleScope
        outputHandler  = $previousConfig.outputHandler
        outputHandlers = $previousConfig.outputHandlers.Clone()
    }

    if ($Framework) {
        $config.framework = $Framework
    }

    if ($BuildFile) {
        $config.buildFileName = $BuildFile
    }

    return $config
}
