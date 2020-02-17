# Helper script for those who want to run psake without importing the module.
# Example run from PowerShell:
# .\psake.ps1 "psakefile.ps1" "BuildHelloWord" "4.0"

# Must match parameter definitions for psake.psm1/invoke-psake
# otherwise named parameter binding fails
[cmdletbinding(PositionalBinding = $false)]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$buildFile,

    [Parameter(Position = 1, Mandatory = $false)]
    [string[]]$taskList = @(),

    [Parameter(Mandatory = $false)]
    [string]$framework,

    [Parameter(Mandatory = $false)]
    [switch]$docs = $false,

    [Parameter(Mandatory = $false)]
    [hashtable]$parameters = @{ },

    [Parameter(Mandatory = $false)]
    [hashtable]$properties = @{ },

    [Parameter(Mandatory = $false)]
    [alias("init")]
    [scriptblock]$initialization = { },

    [Parameter(Mandatory = $false)]
    [switch]$nologo = $false,

    [Parameter(Mandatory = $false)]
    [switch]$detailedDocs = $false,

    [Parameter(Mandatory = $false)]
    [switch]$notr = $false,

    [Parameter(Mandatory = $false, ValueFromRemainingArguments = $true)]
    $buildScriptArguments = $null,

    [Parameter(Mandatory = $false)]
    [switch]$help = $false,

    [Parameter(Mandatory = $false)]
    [string]$scriptPath
)

# setting $scriptPath here, not as default argument, to support calling as "powershell -File psake.ps1"
if (-not $scriptPath) {
    $scriptPath = $(Split-Path -Path $MyInvocation.MyCommand.path -Parent)
}

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module -Name [p]sake -Verbose:$false
Import-Module -Name (Join-Path -Path $scriptPath -ChildPath 'psake.psd1') -Verbose:$false
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

Invoke-psake $buildFile $taskList -framework $framework -docs:$docs -parameters $parameters -properties $properties -init $initialization -nologo:$nologo -detailedDocs:$detailedDocs -notr:$notr $buildScriptArguments

if (!$psake.build_success) {
    exit 1
}
