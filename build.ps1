#requires -Version 5.1
[CmdletBinding()]
param(
    # Build task(s) to execute
    [ValidateSet(
        'Test',
        'Analyze',
        'Pester',
        'Clean',
        'Build',
        'CreateMarkdownHelp',
        'BuildNuget',
        'PublishChocolatey',
        'PublishNuget',
        'PublishPSGallery'
    )]
    [string]$Task = 'Test',

    # Bootstrap dependencies
    [switch]$Bootstrap
)

$sut = Join-Path -Path $PSScriptRoot -ChildPath 'src'
$manifestPath = Join-Path -Path $sut -ChildPath 'psake.psd1'
$version = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath 'output'
$outputNugetDir = Join-Path -Path $outputDir -ChildPath 'nuget'
$outputModDir = Join-Path -Path $outputDir -ChildPath 'psake'
$outputModVerDir = Join-Path -Path $outputModDir -ChildPath $version
$outputManifest = Join-Path -Path $outputModVerDir -ChildPath 'psake.psd1'

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

            $dependencies = $stepCommand.ScriptBlock.Attributes.Where{ $_.TypeId.Name -eq 'DependsOn' }.Name
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
    [CmdletBinding()]
    param()

    Remove-Module -Name psake -Force -ErrorAction SilentlyContinue
    Set-BuildEnvironment -Force
}

function Test {
    [DependsOn(('Build', 'Analyze', 'Pester'))]
    [CmdletBinding()]
    param()
    ''
}

function Analyze {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()

    $analysis = Invoke-ScriptAnalyzer -Path $sut -Recurse -Verbose:$false
    $errors = $analysis | Where-Object { $_.Severity -eq 'Error' }
    $warnings = $analysis | Where-Object { $_.Severity -eq 'Warning' }

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
    [CmdletBinding()]
    param()

    Import-Module -Name $outputManifest -Force

    $pesterParams = @{
        Path     = './tests'
        Output   = 'Detailed'
        PassThru = $true
    }
    $testResults = Invoke-Pester @pesterParams

    if ($testResults.FailedCount -gt 0) {
        throw "$($testResults.FailedCount) tests failed!"
    }
}

function Clean {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()

    if (Test-Path -Path $outputModVerDir) {
        Remove-Item -Path $outputModVerDir -Recurse -Force > $null
    }
}

function Build {
    [DependsOn('Clean')]
    [CmdletBinding()]
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
    [CmdletBinding()]
    param()

    $mdHelpPath = "$PSScriptRoot/docs/reference/functions"
    New-MarkdownHelp -Module psake -OutputFolder $mdHelpPath -Force -Verbose:$VerbosePreference > $null
}

function UpdateMarkdownHelp {
    [DependsOn('Init')]
    [CmdletBinding()]
    param()

    'TODO'
}

function StageNuget {
    [DependsOn('Build')]
    [CmdletBinding()]
    param()

    $here = $PSScriptRoot

    "Staging Nuget Files"

    $dest = $outputNugetDir
    if (Test-Path -Path $dest -PathType Container) {
        Remove-Item -Path $dest -Recurse -Force
    }
    $destTools = Join-Path -Path $dest -ChildPath tools

    Copy-Item -Recurse -Path "$here/build/nuget" -Destination $dest -Exclude 'nuget.exe'
    Copy-Item -Recurse -Path "$outputModVerDir" -Destination "$destTools/psake"
    @('README.md', 'license') | ForEach-Object {
        Copy-Item -Path "$here/$_" -Destination $destTools
    }

    "Updating nuspec version"
    $specPath = "$dest\psake.nuspec"
    $spec = [xml](Get-Content -Raw $specPath)
    $spec.package.metadata.version = $version
    $spec.Save($specPath)
}

function PublishChocolatey {
    [DependsOn('StageNuget')]
    [CmdletBinding()]
    param()

    try {
        Push-Location $outputNugetDir
        choco pack
        if ($null -eq $(choco apikey list -r)) {
            throw "No Choco API key is set! Not publishing choco package."
        }
        choco push --source "'https://push.chocolatey.org/'"
    } finally {
        Pop-Location
    }
}

function PublishNuget {
    [DependsOn('StageNuget')]
    [CmdletBinding()]
    param()

    "Building nuget package version [$version]"
    $nugetInPath = Get-Command 'nuget' -ErrorAction 'SilentlyContinue'
    if (-Not $nugetInPath) {
        Write-Warning "Nuget not detected in path. Using local copy..."
        $nugetBin = Resolve-Path "$PSScriptRoot\build\nuget\NuGet.exe"
    } else {
        $nugetBin = $nugetInPath.Source
    }
    Write-Verbose "Using nuget at $nugetBin"
    try {
        Push-Location $outputNugetDir
        & $nugetBin pack "./psake.nuspec" -Verbosity quiet -Version $version -Properties NoWarn='NU5111,NU5125'
        $nupkg = (Get-ChildItem "psake*.nupkg").Name
        if ($null -eq $ENV:NUGET_API_KEY) {
            throw 'Nuget API is not set! Not publishing.'
        }
        & $nugetBin push $nupkg --api-key $ENV:NUGET_API_KEY --source https://api.nuget.org/v3/index.json
    } finally {
        Pop-Location
    }
}

function PublishPSGallery {
    [DependsOn('Build')]
    [CmdletBinding()]
    param()

    "Publishing version [$Version] to PSGallery.."
    if ($null -eq $env:PSGALLERY_API_KEY) {
        throw 'PSGallery API is not set! Not publishing.'
    }
    $publishParams = @{
        Path        = $outputModVerDir
        Repository  = 'PSGallery'
        Verbose     = $VerbosePreference
        NuGetApiKey = $env:PSGALLERY_API_KEY
    }

    Publish-Module @publishParams
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
