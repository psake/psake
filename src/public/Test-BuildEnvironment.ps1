function Test-BuildEnvironment {
    <#
    .SYNOPSIS
    Tests whether the .NET framework required by a build is available on the
    current machine.

    .DESCRIPTION
    Resolves the MSBuild and .NET runtime directories for the specified
    framework version and checks that every required directory exists.
    Returns $true if the environment is ready, $false otherwise.

    The framework to check is determined in order of precedence:
      1. The -Framework parameter, if supplied.
      2. The framework declared in -BuildFile, if supplied.
      3. The active psake build context (if one is on the stack).
      4. The psake default framework (4.7.2).

    This is useful in Pester specs to skip tests that require a framework
    toolchain that is not installed:

        It 'compiles with MSBuild 4.8' {
            if (-not (Test-BuildEnvironment -Framework '4.8')) {
                Set-ItResult -Skipped -Because 'Framework 4.8 not available'
            }
            # ... rest of test
        }

        It 'uses the project framework' {
            if (-not (Test-BuildEnvironment -BuildFile './psakefile.ps1')) {
                Set-ItResult -Skipped -Because 'Required framework not available'
            }
            # ... rest of test
        }

    .PARAMETER Framework
    The .NET framework version string to test (e.g. '4.8', '3.5', '4.7.2x64').
    Takes precedence over -BuildFile and the active context.

    .PARAMETER BuildFile
    Path to a psake build script. The framework declared in that file is read
    and tested. Ignored when -Framework is also supplied.

    .OUTPUTS
    [bool]

    .EXAMPLE
    Test-BuildEnvironment -Framework '4.8'

    Returns $true when MSBuild 17.0 or 16.0 and the v4.0.30319 runtime
    directory are both present.

    .EXAMPLE
    Test-BuildEnvironment -BuildFile './psakefile.ps1'

    Loads the build file, reads its Framework setting, and returns $true if
    that framework is installed.

    .EXAMPLE
    if (-not (Test-BuildEnvironment)) {
        Write-Warning "Build environment not ready for current framework"
    }

    Tests the framework configured in the active psake context.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Framework')]
    [OutputType([bool])]
    param(
        [Parameter(Position = 0, ParameterSetName = 'Framework')]
        [string]$Framework,

        [Parameter(Mandatory = $true, ParameterSetName = 'BuildFile')]
        [ValidateNotNullOrEmpty()]
        [string]$BuildFile
    )

    # Not in ValidateScript because we want to allow the parameter to be
    # supplied but the file to be missing, and handle that gracefully with a
    # $false return value.
    if ( -not (Test-Path $BuildFile -PathType Leaf)) {
        Write-BuildOutput "Build file not found." "Error"
        return $false
    }

    # Resolve framework string from the most specific source available.
    if (-not $Framework) {
        if ($PSCmdlet.ParameterSetName -eq 'BuildFile') {
            Write-Verbose "Test-BuildEnvironment: reading framework from '$BuildFile'"
            try {
                $invokeInBuildFileScopeSplat = @{
                    BuildFile          = $BuildFile
                    Module             = $MyInvocation.MyCommand.Module
                    SkipSetEnvironment = $true
                    ScriptBlock        = {
                        param($CurrentContext)
                        return $CurrentContext.config.framework
                    }
                }
                $Framework = Invoke-InBuildFileScope @invokeInBuildFileScopeSplat
            } catch {
                Write-Verbose "Could not load build file '$BuildFile': $_"
                return $false
            } finally {
                Restore-Environment
            }
        } elseif ($psake.Context.Count -gt 0) {
            $Framework = $psake.Context.Peek().config.framework
        } else {
            $Framework = $psake.ConfigDefault.Framework
        }
    }

    Write-Verbose "Test-BuildEnvironment: testing framework '$Framework'"

    # On non-Windows there is no .NET Framework toolchain to validate.
    if ((Test-Path Variable:\IsWindows) -and -not $IsWindows) {
        Write-Verbose "Non-Windows platform — framework check skipped"
        return $true
    }

    try {
        $dirs = Resolve-FrameworkDirectories -Framework $Framework
    } catch {
        Write-Verbose "Framework '$Framework' could not be resolved: $_"
        return $false
    }

    $allExist = $true
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir -PathType Container)) {
            Write-Verbose "Required directory not found: $dir"
            $allExist = $false
        }
    }

    return $allExist
}
