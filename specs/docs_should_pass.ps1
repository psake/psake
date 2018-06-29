
Task default -depends CheckDocs

Task CheckDocs {
    $NL = [System.Environment]::NewLine
    $docArray = @(Invoke-psake .\nested\docs.ps1 -docs -nologo | Out-String -Stream -Width 120)
    $docString = (($docArray | Foreach-Object Trim) -join $NL).Trim()

    $expectedDoc = @"
Name             Alias Depends On                         Default Description
----             ----- ----------                         ------- -----------
Compile                CompileSolutionA, CompileSolutionB    True
CompileSolutionA                                                  Compiles solution A
CompileSolutionB
IntegrationTests
Test                   UnitTests, IntegrationTests           True
UnitTests        ut
"@ -split $NL

    $expectedDocString = (($expectedDoc | Foreach-Object Trim) -join $NL).Trim()

    Assert ($docString -eq $expectedDocString) "Unexpected simple doc: $docString"
}
