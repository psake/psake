param($installPath, $toolsPath, $package)

$psakeModule = Join-Path -Path $toolsPath -ChildPath 'psake/psake.psd1'
Import-Module -Name $psakeModule
