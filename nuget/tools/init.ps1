param($installPath, $toolsPath, $package)

$psakeModule = Join-Path $toolsPath psake.psm1
import-module $psakeModule

@"
========================
PSake - Automated builds with powershell
========================
"@ | Write-Host