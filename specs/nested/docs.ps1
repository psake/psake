
Task default -depends Compile,Test

Task Compile -depends CompileSolutionA,CompileSolutionB

Task Test -depends UnitTests,IntegrationTests

Task CompileSolutionA -description 'Compiles solution A' {}

Task CompileSolutionB {}

Task UnitTests -alias 'ut' {}

Task IntegrationTests {}
