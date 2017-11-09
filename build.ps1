[cmdletbinding()]
param()

Get-PackageProvider -Name Nuget -ForceBootstrap -Verbose:$false | Out-Null
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -Verbose:$false

'Pester' | Foreach-Object {
    if (-not (Get-Module -Name $_ -ErrorAction SilentlyContinue)) {
        Install-Module -Name $_ -AllowClobber -Scope CurrentUser -Force
        Import-Module -Name $_
    }
}

if ($env:TRAVIS) {
    . "$PSScriptRoot/build/travis.ps1"
}

$testResults = Invoke-Pester -Path ./tests -PassThru -OutputFile ./testResults.xml

# Upload test artifacts to AppVeyor
if ($env:APPVEYOR_JOB_ID) {
    $wc = New-Object 'System.Net.WebClient'
    $wc.UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path ./testResults.xml))
}

if ($testResults.FailedCount -gt 0) {
    throw "$($testResults.FailedCount) tests failed!"
}
