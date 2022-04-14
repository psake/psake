$config.outputHandlers.heading = { Param($output) Write-Output "heading : $output" };
$config.outputHandlers.default = { Param($output) Write-Output "default : $output" };
$config.outputHandlers.debug = { Param($output) Write-Output "debug : $output" };
$config.outputHandlers.warning = { Param($output) Write-Output "warning : $output" };
$config.outputHandlers.error = { Param($output) Write-Output "error : $output" };
$config.outputHandlers.success = { Param($output) Write-Output "success : $output" };
$config.verboseError = $true;
