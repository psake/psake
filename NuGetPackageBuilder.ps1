$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
$manifestPath = Join-Path $dir psake.psd1

try
{
    $manifest = Test-ModuleManifest -Path $manifestPath -WarningAction SilentlyContinue -ErrorAction Stop
    $version = $manifest.Version.ToString()
}
catch
{
    throw
}

"Version number $version"

$destDir = "$dir\bin"
if (Test-Path $destDir -PathType container) {
    Remove-Item $destDir -Recurse -Force
}

Copy-Item -Recurse $dir\nuget $destDir
Copy-Item -Recurse $dir\en-US $destDir\tools\en-US
Copy-Item -Recurse $dir\examples $destDir\tools\examples
@( "psake.cmd", "psake.ps1", "psake.psm1", "psake.psd1", "psake-config.ps1", "README.markdown", "license.txt") |
    ForEach-Object { Copy-Item $dir\$_ $destDir\tools }

.\nuget pack "$destDir\psake.nuspec" -Verbosity quiet -Version $version
