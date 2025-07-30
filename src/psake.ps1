# Helper script for those who want to run psake without importing the module.
# Example run from PowerShell:
# .\psake.ps1 "psakefile.ps1" "BuildHelloWord" "4.0"

# Must match parameter definitions for psake.psm1/invoke-psake
# otherwise named parameter binding fails
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$BuildFile,

    [Parameter(Position = 1, Mandatory = $false)]
    [string[]]$TaskList = @(),

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$Framework,

    [Parameter(Position = 3, Mandatory = $false)]
    [switch]$Docs = $false,

    [Parameter(Position = 4, Mandatory = $false)]
    [System.Collections.Hashtable]$Parameters = @{},

    [Parameter(Position = 5, Mandatory = $false)]
    [System.Collections.Hashtable]$Properties = @{},

    [Parameter(Position = 6, Mandatory = $false)]
    [alias("init")]
    [scriptblock]$Initialization = {},

    [Parameter(Position = 7, Mandatory = $false)]
    [switch]$NoLogo = $false,

    [Parameter(Position = 8, Mandatory = $false)]
    [switch]$Help = $false,

    [Parameter(Position = 9, Mandatory = $false)]
    [string]$ScriptPath,

    [Parameter(Position = 10, Mandatory = $false)]
    [switch]$DetailedDocs = $false,

    # spell-checker:ignore notr
    [Parameter(Position = 11, Mandatory = $false)]
    [Alias("notr")]
    [switch]$NoTimeReport = $false
)

# setting $ScriptPath here, not as default argument, to support calling as "powershell -File psake.ps1"
if (-not $ScriptPath) {
    $ScriptPath = $(Split-Path -Path $MyInvocation.MyCommand.path -Parent)
}

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module -Name [p]sake -Verbose:$false
Import-Module -Name (Join-Path -Path $ScriptPath -ChildPath 'psake.psd1') -Verbose:$false
if ($help) {
    Get-Help -Name Invoke-psake -Full
    return
}

if ($BuildFile -and (-not (Test-Path -Path $BuildFile))) {
    $absoluteBuildFile = (Join-Path -Path $ScriptPath -ChildPath $BuildFile)
    if (Test-Path -Path $absoluteBuildFile) {
        $BuildFile = $absoluteBuildFile
    }
}

$psakeSplat = @{
    BuildFile      = $BuildFile
    TaskList       = $TaskList
    Framework      = $Framework
    Docs           = $Docs
    Parameters     = $Parameters
    Properties     = $Properties
    Initialization = $Initialization
    NoLogo         = $NoLogo
    DetailedDocs   = $DetailedDocs
    NoTimeReport   = $NoTimeReport
}
Invoke-psake @psakeSplat

if (!$psake.build_success) {
    exit 1
}
