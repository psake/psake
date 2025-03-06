$config.outputHandlers.Heading = { Param($output) Write-Output "Heading : $output" }
$config.outputHandlers.Default = { Param($output) Write-Output "Default : $output" }
$config.outputHandlers.Debug = { Param($output) Write-Output "Debug : $output" }
$config.outputHandlers.Warning = { Param($output) Write-Output "Warning : $output" }
$config.outputHandlers.Error = { Param($output) Write-Output "Error : $output" }
$config.outputHandlers.Success = { Param($output) Write-Output "Success : $output" }
$config.verboseError = $true
