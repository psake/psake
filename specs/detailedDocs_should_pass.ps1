
Task default -depends CheckDetailedDocs

Task CheckDetailedDocs {
    $doc = Invoke-psake .\nested\docs.ps1 -detailedDocs -nologo | Out-String

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




"@
    Assert ($doc -eq $expectedDoc) "Unexpected simple doc: $doc"

}
