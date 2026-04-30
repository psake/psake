function Framework {
    <#
    .SYNOPSIS
    Sets the version of the .NET framework you want to use during build.

    .DESCRIPTION
    Overrides the psake default framework, determining which MSBuild and
    runtime directories are used by all tasks in the build.

    .PARAMETER Framework
    Framework version string. Append 'x86' or 'x64' to force bitness;
    otherwise bitness matches the current PowerShell process.
    Supported values: '1.0', '1.1', '2.0', '2.0x86', '2.0x64', '3.0',
    '3.0x86', '3.0x64', '3.5', '3.5x86', '3.5x64', '4.0', '4.0x86',
    '4.0x64', '4.5', '4.5x86', '4.5x64', '4.5.1', '4.5.1x86', '4.5.1x64'.
    Default is '3.5*' (bitness auto-detected).

    .EXAMPLE
    Framework "4.0"
    Task default -depends Compile
    Task Compile -depends Clean {
        msbuild /version
    }

    Uses MSBuild v4.0 for the build.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Framework
    )

    Write-Debug "Setting framework to '$Framework'"
    $psake.Context.Peek().config.framework = $Framework
    $psake.Context.Peek().config.frameworkIsExplicit = $true

    Set-BuildEnvironment
}
