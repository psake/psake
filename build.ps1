#requires -Version 5.1

[cmdletbinding()]
param(
    # Build task(s) to execute
    [validateSet('Test', 'Analyze', 'Pester', 'Clean', 'Build', 'CreateMarkdownHelp', 'BuildNuget', 'PublishChocolatey', 'PublishPSGallery')]
    [string]$Task = 'Test',

    # Bootstrap dependencies
    [switch]$Bootstrap
)

$sut             = Join-Path -Path $PSScriptRoot    -ChildPath 'src'
$manifestPath    = Join-Path -Path $sut             -ChildPath 'psake.psd1'
$version         = (Import-PowerShellDataFile       -Path $manifestPath).ModuleVersion
$outputDir       = Join-Path -Path $PSScriptRoot    -ChildPath 'output'
$outputModDir    = Join-Path -Path $outputDir       -ChildPath 'psake'
$outputModVerDir = Join-Path -Path $outputModDir    -ChildPath $version
$outputManifest  = Join-Path -Path $outputModVerDir -ChildPath 'psake.psd1'
$testResultsPath = Join-Path -Path $outputDir       -ChildPath testResults.xml

$PSDefaultParameterValues = @{
    'Get-Module:Verbose'    = $false
    'Remove-Module:Verbose' = $false
    'Import-Module:Verbose' = $false
}

if ($Bootstrap) {
    Get-PackageProvider -Name Nuget -ForceBootstrap > $null
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module -Name PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }
    Import-Module -Name PSDepend -Verbose:$false
    Invoke-PSDepend -Path './requirements.psd1' -Install -Import -Force -WarningAction SilentlyContinue
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
            foreach ($dependency in $dependencies) {
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

    Remove-Module -Name psake -Force -ErrorAction SilentlyContinue
    Set-BuildEnvironment -Force
}

function Test {
    [DependsOn(('Build', 'Analyze', 'Pester'))]
    [cmdletbinding()]
    param()
    ''
}

function Analyze {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    $analysis = Invoke-ScriptAnalyzer -Path $sut -Recurse -Verbose:$false
    $errors   = $analysis | Where-Object {$_.Severity -eq 'Error'}
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

    Import-Module -Name $outputManifest -Force

    $pesterParams = @{
        Path         = './tests'
        Output       = 'Detailed'
        PassThru     = $true
    }
    $testResults = Invoke-Pester @pesterParams

    if ($testResults.FailedCount -gt 0) {
        throw "$($testResults.FailedCount) tests failed!"
    }
}

function Clean {
    [DependsOn('Init')]
    [cmdletbinding()]
    param()

    if (Test-Path -Path $outputModVerDir) {
        Remove-Item -Path $outputModVerDir -Recurse -Force > $null
    }
}

function Build {
    [DependsOn('Clean')]
    [cmdletbinding()]
    param()

    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory > $null
    }
    New-Item -Path $outputModVerDir -ItemType Directory > $null
    Copy-Item -Path (Join-Path -Path $sut -ChildPath *) -Destination $outputModVerDir -Recurse
    Copy-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath 'examples') -Destination $outputModVerDir -Recurse
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
    [DependsOn('Build')]
    [cmdletbinding()]
    param()

    $here = $PSScriptRoot

    "Building nuget package version [$version]"

    $dest = Join-Path -Path $PSScriptRoot -ChildPath bin
    if (Test-Path -Path $dest -PathType Container) {
        Remove-Item -Path $dest -Recurse -Force
    }
    $destTools = Join-Path -Path $dest -ChildPath tools

    Copy-Item -Recurse -Path "$here/build/nuget" -Destination $dest -Exclude 'nuget.exe'
    Copy-Item -Recurse -Path "$outputModVerDir" -Destination "$destTools/psake"
    @('README.md', 'license') | Foreach-Object {
        Copy-Item -Path "$here/$_" -Destination $destTools
    }

    & "$here/build/nuget/nuget.exe" pack "$dest/psake.nuspec" -Verbosity quiet -Version $version
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
    exit 1
} finally {
    Pop-Location
}
