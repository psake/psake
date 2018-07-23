$nugetExecutablePath = Join-Path -Path $env:ChocolateyInstall -ChildPath 'bin'
$packageBatchFileName = Join-Path -Path $nugetExecutablePath -ChildPath 'psake.bat'

$psakeDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#$path = ($psakeDir | Split-Path | Join-Path -ChildPath  'psake.cmd')
$path = Join-Path -Path $psakeDir -ChildPath 'psake/psake.cmd'
Write-Host "Adding $packageBatchFileName and pointing to $path"
"@echo off
""$path"" %*" | Out-File $packageBatchFileName -encoding ASCII

Write-Host "PSake is now ready. You can type 'psake' from any command line at any path. Get started by typing 'psake /?'"
