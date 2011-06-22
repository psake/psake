# Helper script for those who want to run psake without importing the module.
# Example:
# .\psake.ps1 "default.ps1" "BuildHelloWord" "4.0" 

# Must match parameter definitions for psake.psm1/invoke-psake 
# otherwise named parameter binding fails
param(
  [Parameter(Position=0,Mandatory=0)]
  [string]$buildFile = 'default.ps1',
  [Parameter(Position=1,Mandatory=0)]
  [string[]]$taskList = @(),
  [Parameter(Position=2,Mandatory=0)]
  [string]$framework = '3.5',
  [Parameter(Position=3,Mandatory=0)]
  [switch]$docs = $false,
  [Parameter(Position=4,Mandatory=0)]
  [System.Collections.Hashtable]$parameters = @{},
  [Parameter(Position=5, Mandatory=0)]
  [System.Collections.Hashtable]$properties = @{},
  [Parameter(Position=6, Mandatory=0)]
  [string]$scriptPath = $(Split-Path -parent $MyInvocation.MyCommand.path),
  [Parameter(Position=7, Mandatory=0)]
  [switch]$nologo = $false
)

remove-module psake -ea 'SilentlyContinue'
import-module (join-path $scriptPath psake.psm1)
if (-not(test-path $buildFile))
{
    $absoluteBuildFile = (join-path $scriptPath $buildFile)
	if (test-path $absoluteBuildFile)
	{
		$buildFile = $absoluteBuildFile
	}
} 
invoke-psake $buildFile $taskList $framework $docs $parameters $properties $nologo
exit $lastexitcode