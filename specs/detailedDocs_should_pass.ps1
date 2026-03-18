
Task default -Depends CheckDetailedDocs

Task CheckDetailedDocs {
    $NL = [System.Environment]::NewLine

    if ($PSStyle) {
        $origOutputRendering = $PSStyle.OutputRendering
        $PSStyle.OutputRendering = 'PlainText'
    }
    $psake.ConfigDefault.OutputHandlers.Default = { param($output) Write-Host $output }

    $docArray = @(Invoke-Psake $PSScriptRoot\nested\docs.ps1 -DetailedDocs -NoLogo | Out-String -Stream -Width 120)
    $docString = (($docArray | ForEach-Object Trim) -join $NL).Trim()

    $expectedDoc = @"
Name        : Compile
Alias       :
Description :
Depends On  : CompileSolutionA, CompileSolutionB
Default     : True

Name        : CompileSolutionA
Alias       :
Description : Compiles solution A
Depends On  :
Default     :

Name        : CompileSolutionB
Alias       :
Description :
Depends On  :
Default     :

Name        : IntegrationTests
Alias       :
Description :
Depends On  :
Default     :

Name        : Test
Alias       :
Description :
Depends On  : UnitTests, IntegrationTests
Default     : True

Name        : UnitTests
Alias       : ut
Description :
Depends On  :
Default     :
"@ -split $NL

    $expectedDocString = (($expectedDoc | ForEach-Object Trim) -join $NL).Trim()

    if ($origOutputRendering) {
        $PSStyle.OutputRendering = $origOutputRendering
    }

    Assert ($docString -eq $expectedDocString) "Unexpected simple doc: $docString"
}
