function CreateConfigurationForNewContext {
    param(
        [string] $buildFile,
        [string] $framework
    )

    $previousConfig = Get-CurrentConfigurationOrDefault

    $config = New-Object psobject -Property @{
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

    if ($framework) {
        $config.framework = $framework
    }

    if ($buildFile) {
        $config.buildFileName = $buildFile
    }

    return $config
}
