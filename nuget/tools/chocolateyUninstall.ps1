$nugetPath = $env:ChocolateyInstall
$nugetExePath = Join-Path -Path $nuGetPath -ChildPath 'bin'
$packageBatchFileName = Join-Path -Path $nugetExePath -ChildPath 'psake.bat'

Remove-Item -Path $packageBatchFileName -Force -Confirm:$false

Write-Host 'PSake has been uninstalled'
