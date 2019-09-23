$nugetBinPath       = Join-Path -Path $env:ChocolateyInstall -ChildPath 'bin'
$packageBatFileName = Join-Path -Path $nugetBinPath -ChildPath 'psake.bat'

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module -Name [p]sake -Verbose:$false

Remove-Item -Path $packageBatFileName -Force -Confirm:$false

Write-Host 'PSake has been uninstalled'
