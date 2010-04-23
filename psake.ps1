# Helper script for those who want to run psake without importing the module.
# Example:
# .\psake.ps1 "default.ps1" "BuildHelloWord" "4.0" 
#
try
{
	$scriptPath = Split-Path -parent $MyInvocation.InvocationName;
	import-module (join-path $scriptPath psake.psm1)
	invoke-psake @args
}
finally
{
	remove-module psake
}