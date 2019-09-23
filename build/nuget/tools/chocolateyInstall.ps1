$nugetBinPath       = Join-Path -Path $env:ChocolateyInstall -ChildPath 'bin'
$packageBatFileName = Join-Path -Path $nugetBinPath -ChildPath 'psake.bat'

$psakeDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#$path = ($psakeDir | Split-Path | Join-Path -ChildPath  'psake.cmd')
$path = Join-Path -Path $psakeDir -ChildPath 'psake/psake.cmd'
Write-Host "Adding $packageBatFileName and pointing to $path"
"@echo off
""$path"" %*" | Out-File $packageBatFileName -encoding ASCII

Write-Host "PSake is now ready. You can type 'psake' from any command line at any path. Get started by typing 'psake /?'"
