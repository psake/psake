
Task default -depends CheckDocs

Task CheckDocs {

    $docArray = (Invoke-psake .\nested\docs.ps1 -docs -nologo | Out-String).Split("`n")
    $docString = (($docArray | Foreach-Object {
        $_.Trim()
    }) -join "`n").Trim()

    $expectedDoc = @"
Name             Alias Depends On                         Default Description
----             ----- ----------                         ------- -----------
Compile                CompileSolutionA, CompileSolutionB    True
CompileSolutionA                                                  Compiles solution A
CompileSolutionB
IntegrationTests
Test                   UnitTests, IntegrationTests           True
UnitTests        ut
"@
    $expectedDoc = $expectedDoc.Split("`n")
    $expectedDocString = (($expectedDoc | Foreach-Object {
        $_.Trim()
    }) -join "`n").Trim()

    Assert ($docString -eq $expectedDocString) "Unexpected simple doc: $doc"
}
