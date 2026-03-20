function Set-BuildEnvironment {
    [CmdletBinding()]
    param ()

    Write-Debug "Setting build environment"
    if (!(Test-Path Variable:\IsWindows) -or $IsWindows) {
        $framework = $psake.Context.peek().config.framework
        Write-Debug "Configuring .NET Framework '$framework'"

        $frameworkDirs = Resolve-FrameworkDirectories -Framework $framework

        $frameworkDirs | ForEach-Object {
            Assert (Test-Path $_ -PathType Container) (
                $msgs.error_no_framework_install_dir_found -f $_
            )
        }

        Write-Debug "Prepending to `$env:PATH: $($frameworkDirs -join ';')"
        $env:PATH = ($frameworkDirs -join ";") + ";$env:PATH"
    }

    # if any error occurs in a PS function then "stop" processing immediately
    # this does not effect any external programs that return a non-zero exit code
    $global:ErrorActionPreference = "Stop"
}
