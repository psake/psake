# Setup dotnet
. "$PSScriptRoot/tools.ps1"
$dotnetArguments = @{
    Channel = 'Current'
    Version = 'latest'
    NoSudo = $false
}
Install-Dotnet @dotnetArguments
$Env:PATH += "$([IO.Path]::PathSeparator)$Env:HOME/.dotnet"
dotnet build -version -nologo