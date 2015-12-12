param(
    [string]$version = "1.0.0"
    )

"Version number $version"

$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath

$destDir = "$dir\bin"
if (Test-Path $destDir -PathType container) {
    Remove-Item $destDir -Recurse -Force
}

Copy-Item -Recurse $dir\nuget $destDir
Copy-Item -Recurse $dir\en-US $destDir\tools\en-US
Copy-Item -Recurse $dir\examples $destDir\tools\examples
@( "psake.cmd", "psake.ps1", "psake.psm1", "psake-config.ps1", "README.markdown", "license.txt") |
    % { Copy-Item $dir\$_ $destDir\tools }

.\nuget pack "$destDir\psake.nuspec" -Verbosity quiet -Version $version
