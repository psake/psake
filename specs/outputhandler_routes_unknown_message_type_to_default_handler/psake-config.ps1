$config.outputHandlers.Heading = $null
$config.outputHandlers.Default = { Param($output) Write-Output "Default : $output" }
$config.outputHandlers.Debug = $null
$config.outputHandlers.Warning = $null
$config.outputHandlers.Error = $null
$config.outputHandlers.Success = $null
