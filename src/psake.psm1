# psake
# Copyright (c) 2012 James Kovacs
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# TODO: Remove this when we drop support for PowerShell 2.0
#Requires -Version 2.0

if ($PSVersionTable.PSVersion.Major -ge 3) {
    $script:IgnoreError = 'Ignore'
} else {
    $script:IgnoreError = 'SilentlyContinue'
}

$script:nl = [System.Environment]::NewLine

# Dot source public/private functions
$dotSourceParams = @{
    Filter      = '*.ps1'
    Recurse     = $true
    ErrorAction = 'Stop'
}
$enums = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'enums') @dotSourceParams )
$classes = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'classes') @dotSourceParams )
$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public') @dotSourceParams )
$public = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'public') @dotSourceParams )
$private = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'private') @dotSourceParams)
foreach ($import in @($enums + $classes + $public + $private)) {
    try {
        . $import.FullName
    } catch {
        throw "Unable to dot source [$($import.FullName)]"
    }
}

$importLocalizedDataSplat = @{
    BindingVariable = 'msgs'
    FileName        = 'messages.psd1'
    ErrorAction     = $script:IgnoreError
}

Import-LocalizedData @importLocalizedDataSplat

$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDir psake.psd1
$manifest = Test-ModuleManifest -Path $manifestPath -WarningAction SilentlyContinue

$psakeConfigFile = 'psake-config.ps1'

$psake = @{}

$psake.version = $manifest.Version.ToString()
$psake.Context = New-Object system.collections.stack # holds onto the current state of all variables
$psake.run_by_psake_build_tester = $false # indicates that build is being run by psake-BuildTester
$psake.LoadedTaskModules = @{}
$psake.ReferenceTasks = @{}

# TODO: Replace New-Object with [PSCustomObject] when dropping support for PowerShell 2.0
#region Default Psake Configuration
# Contains default configuration, can be overridden in psake-config.ps1 in
# directory with psake.psm1 or in directory with current build script
$psake.ConfigDefault = New-Object 'PSObject' -Property @{
    BuildFileName       = "psakefile.ps1"
    LegacyBuildFileName = "default.ps1"
    Framework           = "4.0"
    TaskNameFormat      = "Executing {0}"
    VerboseError        = $False
    ColoredOutput       = $True
    Modules             = $Null
    ModuleScope         = ""
    OutputHandler       = {
        [CmdLetBinding()]
        param (
            [Parameter(Position = 0)]
            [object]$Output,
            [Parameter(Position = 1)]
            [string]$OutputType = 'Default'
        )

        process {
            if ($psake.Context.peek().config.OutputHandlers.$OutputType -is [scriptblock]) {
                & $psake.Context.peek().config.OutputHandlers.$OutputType $Output
            } elseif ($OutputType -ne "default") {
                Write-Warning "No OutputHandler has been defined for $OutputType output. The default OutputHandler will be used."
                Write-PsakeOutput -Output $Output -OutputType 'default'
            } else {
                Write-Warning "The default OutputHandler is invalid. Write-Host will be used."
                # We use Write-Host because this should not output something that is captured by a variable
                Write-Host $Output
            }
        }
    }
    OutputHandlers      = @{
        Heading = {
            param($Output)
            Write-ColoredOutput -Message $Output -ForegroundColor 'Cyan'
        }
        Default = {
            param($Output)
            Write-Output $Output
        }
        Debug   = {
            param($Output)
            Write-Debug $Output
        }
        Warning = {
            param($Output)
            Write-ColoredOutput -Message $Output -ForegroundColor 'Yellow'
        }
        Error   = {
            param($Output)
            Write-ColoredOutput -Message $Output -ForegroundColor 'Red'
        }
        Success = {
            param($Output)
            Write-ColoredOutput -Message $Output -ForegroundColor 'Green'
        }
    }
}
#endregion

$psake.build_success = $false # indicates that the current build was successful
$psake.build_script_file = $null # contains a System.IO.FileInfo for the current build script
$psake.build_script_dir = "" # contains a string with fully-qualified path to current build script
$psake.error_message = $null # contains the error message which caused the script to fail

Import-PsakeConfiguration

Export-ModuleMember -Function $public.BaseName -Variable psake
