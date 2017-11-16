# Helper script for those who want to run psake without importing the module.
# Example run from PowerShell:
# .\psake.ps1 "psakefile.ps1" "BuildHelloWord" "4.0"

# Must match parameter definitions for psake.psm1/invoke-psake
# otherwise named parameter binding fails
[cmdletbinding()]
param(
    [string]$buildFile,
    [string[]]$taskList = @(),
    [string]$framework,
    [switch]$docs = $false,
    [System.Collections.Hashtable]$parameters = @{},
    [System.Collections.Hashtable]$properties = @{},
    [alias('init')]
    [scriptblock]$initialization = {},
    [switch]$nologo = $false,
    [switch]$help = $false,
    [string]$scriptPath,
    [switch]$detailedDocs = $false
)

# setting $scriptPath here, not as default argument, to support calling as "powershell -File psake.ps1"
if (!$scriptPath) {
    $scriptPath = $(Split-Path -Path $MyInvocation.MyCommand.path -Parent)
}

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module -Name [p]sake -Verbose:$false
Import-Module -Name (Join-Path -Path $scriptPath -ChildPath 'psake/psake.psd1') -Verbose:$false
if ($help) {
    Get-Help -Name Invoke-psake -Full
    return
}

if ($buildFile -and (-not (Test-Path -Path $buildFile))) {
    $absoluteBuildFile = (Join-Path -Path $scriptPath -ChildPath $buildFile)
    if (Test-path -Path $absoluteBuildFile) {
        $buildFile = $absoluteBuildFile
    }
}

Invoke-psake $buildFile $taskList $framework $docs $parameters $properties $initialization $nologo $detailedDocs
