#requires -Version 5.1

[cmdletbinding()]
param(
    [validateSet('Test', 'Analyze', 'Pester', 'CreateMarkdownHelp', 'BuildNuget', 'PublishChocolatey', 'PublishPSGallery')]
    [string]$Task = 'Test'
)

$sut = Join-Path -Path $PSScriptRoot -ChildPath 'psake'

$PSDefaultParameterValues = @{
    'Get-Module:Verbose' = $false
    'Remove-Module:Verbose' = $false
    'Import-Module:Verbose' = $false
}

# Taken with love from Jaykul @ https://gist.github.com/Jaykul/e0c08be051bed56d62474ae12b9b1b8a
class DependsOn : System.Attribute {
    [string[]]$Name

    DependsOn([string[]]$name) {
        $this.Name = $name
    }
}
function Invoke-Step {
    <#
        .Synopsis
            Runs a command, taking care to run it's dependencies first
        .Description
            Invoke-Step supports the [DependsOn("...")] attribute to allow you to write tasks or build steps that take dependencies on other tasks completing first.

            When you invoke a step, dependencies are run first, recursively. The algorithm for this is depth-first and *very* naive. Don't build cycles!
       .Example
            function init {
                param()
                Write-Information "INITIALIZING build variables"
            }

            function update {
                [DependsOn("init")]param()
                Write-Information "UPDATING dependencies"
            }

            function build {
                [DependsOn(("update","init"))]param()
                Write-Information "BUILDING: $ModuleName from $Path"
            }

            Invoke-Step build -InformationAction continue

            Defines three steps with dependencies, and invokes the "build" step.
            Results in this output:

            Invoking Step: init
            Invoking Step: update
            Invoking Step: build

    #>
    [CmdletBinding()]
    param(
        [string]$Step,
        [string]$Script
    )

    begin {
        # Source Build Scripts, if any
        if ($Script) {
            . $Script
        }

        # Don't reset on nested calls
        if (((Get-PSCallStack).Command -eq 'Invoke-Step').Count -eq 1) {
            $script:InvokedSteps = @()
        }
    }

    end {
        if ($stepCommand = Get-Command -Name $Step -CommandType Function) {

            $dependencies = $stepCommand.ScriptBlock.Attributes.Where{$_.TypeId.Name -eq 'DependsOn'}.Name
            foreach($dependency in $dependencies) {
                if ($dependency -notin $script:InvokedSteps) {
                    Invoke-Step -Step $dependency
                }
            }

            if ($Step -notin $script:InvokedSteps) {
                Write-Host "Invoking Step: $Step" -ForegroundColor Cyan
                try {
                    & $stepCommand
                    $script:InvokedSteps += $Step
                } catch {
                    throw $_
                }
            }
        } else {
            throw "Could not find step [$Step]"
        }
    }
}

function Init {
    [cmdletbinding()]
    param()

    $psGallery = Get-PSRepository -Name PSGallery
    if ($psGallery.InstallationPolicy -ne 'Trusted') {
        Get-PackageProvider -Name Nuget -ForceBootstrap -Verbose:$false | Out-Null
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false
    }

    'Pester', 'PlatyPS', 'PSScriptAnalyzer' | Foreach-Object {
        if (-not (Get-Module -Name $_ -ListAvailable -ErrorAction SilentlyContinue)) {
            Install-Module -Name $_ -AllowClobber -Scope CurrentUser -Force
            Import-Module -Name $_
        }
    }

    Remove-Module -Name psake -Force -ErrorAction SilentlyContinue
    Import-Module -Name $sut -Global
}

function Test {
    [DependsOn(('Analyze', 'Pester'))]
    [cmdletbinding()]
    param()
    ''
}

function Analyze {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    $analysis = Invoke-ScriptAnalyzer -Path $sut -Recurse -Verbose:$false
    $errors = $analysis | Where-Object {$_.Severity -eq 'Error'}
    $warnings = $analysis | Where-Object {$_.Severity -eq 'Warning'}

    if (($errors.Count -eq 0) -and ($warnings.Count -eq 0)) {
        'PSScriptAnalyzer passed without errors or warnings'
    }

    if (@($errors).Count -gt 0) {
        Write-Error -Message 'One or more Script Analyzer errors were found. Build cannot continue!'
        $errors | Format-Table -AutoSize
    }

    if (@($warnings).Count -gt 0) {
        Write-Warning -Message 'One or more Script Analyzer warnings were found. These should be corrected.'
        $warnings | Format-Table -AutoSize
    }
}

function Pester {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    if ($env:TRAVIS) {
        . "$PSScriptRoot/build/travis.ps1"
    }

    $testResultsPath = "$PSScriptRoot/testResults.xml"
    $pesterParams = @{
        Path = './tests'
        OutputFile = $testResultsPath
        OutputFormat = 'NUnitXml'
        PassThru = $true
        PesterOption = @{
            IncludeVSCodeMarker = $true
        }
    }
    $testResults = Invoke-Pester @pesterParams

    # Upload test artifacts to AppVeyor
    if ($env:APPVEYOR_JOB_ID) {
        $wc = New-Object 'System.Net.WebClient'
        $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", $testResultsPath)
    }

    if ($testResults.FailedCount -gt 0) {
        throw "$($testResults.FailedCount) tests failed!"
    }
}

function CreateMarkdownHelp {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    $mdHelpPath = "$PSScriptRoot/docs/reference/functions"
    New-MarkdownHelp -Module psake -OutputFolder $mdHelpPath -Force -Verbose:$VerbosePreference > $null
}

function UpdateMarkdownHelp {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    'TODO'
}

function BuildNuget {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    $here = $PSScriptRoot
    $manifestPath = "$here/psake/psake.psd1"

    try {
        $manifest = Test-ModuleManifest -Path $manifestPath -WarningAction SilentlyContinue -ErrorAction Stop
        $version = $manifest.Version.ToString()
    }
    catch {
        throw $_
    }

    "Building nuget package version [$version]"

    $dest = "$here/bin"
    if (Test-Path $dest -PathType Container) {
        Remove-Item -Path $dest -Recurse -Force
    }
    $destTools = "$dest/tools"

    Copy-Item -Recurse -Path "$here/nuget" -Destination $dest
    Copy-Item -Recurse -Path "$here/psake" -Destination $destTools
    Copy-Item -Recurse -Path "$here/examples" -Destination "$destTools/examples"
    @('psake.cmd', 'psake.ps1', 'psake-config.ps1', 'README.md', 'license.txt') | Foreach-Object {
        Copy-Item -Path "$here/$_" -Destination $destTools
    }

    & "$here/nuget.exe" pack "$dest/psake.nuspec" -Verbosity quiet -Version $version
}

function PublishChocolatey {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    'TODO'
}

function PublishPSGallery {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    'TODO'
}

try {
    Push-Location
    Invoke-Step $Task
} catch {
    throw $_
} finally {
    Pop-Location
}
