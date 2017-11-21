$nugetPath = $env:ChocolateyInstall
$nugetExePath = Join-Path -Path $nuGetPath -ChildPath 'bin'
$packageBatchFileName = Join-Path -Path $nugetExePath -ChildPath 'psake.bat'

# '[p]sake' is the same as 'psake' but $Error is not polluted
Remove-Module -Name [p]sake -Verbose:$false

Remove-Item -Path $packageBatchFileName -Force -Confirm:$false

Write-Host 'PSake has been uninstalled'
