
Task default -depends CheckDocs

Task CheckDocs {

    $doc = Invoke-psake .\nested\docs.ps1 -docs -nologo | Out-String

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
    Assert ($doc -eq $expectedDoc) "Unexpected simple doc: $doc"
}
