$config.outputHandlers.heading = $null
$config.outputHandlers.default = { Param($output) Write-Output "default : $output" };
$config.outputHandlers.debug = $null
$config.outputHandlers.warning = $null
$config.outputHandlers.error = $null
$config.outputHandlers.success = $null
