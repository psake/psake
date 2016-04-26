A psake build script contains calls to functions that the psake build engine will execute.

The functions are the following:

|Function|Description|Required|
|--------|-----------|--------|
|_Include()_|Call this function to have psake include the functions of another file into your script|no|
|_Properties()_|Call this function to set your properties|no|
|_Task()_|This is the main function that you write to execute a step in your build script. NOTE: There can be only one task function that is named "default" in your psake script and it cannot contain any code. psake will throw an exception if it finds more than one default task function or if the default task function contains code|yes|
|_Exec()_|Call a command-line program and throw an exception if it returns a non-zero DOS exit code|no|
|_Assert()_|Use to simplify writing conditional statements|no|
|_FormatTaskName()_|Allows you to reformat how psake displays the currently running task|no|
|_TaskSetup()_|A function that will run before each task is executed|no|
|_TaskTearDown()_|A function that will run after each task|no|

An example psake script:
<hr/>

```
Task default -Depends Test

Task Test -Depends Compile, Clean {
   "This is a test"
 }

Task Compile -Depends Clean {
   "Compile"
 }

Task Clean {
   "Clean"
 }
```
<hr/>
<p>The following is a BNF for a psake build script:</p>

pre. <BuildScript> ::= <Includes> 
                | <Properties>
                | <FormatTaskName> 
                | <TaskSetup> 
                | <TaskTearDown> 
                | <Tasks> 
<Includes> ::= Include <StringLiteral> | <Includes>
<Properties> ::= Properties <ScriptBlock> | <Properties>
<FormatTaskName> ::= FormatTaskName <Stringliteral>
<TaskSetup> ::= TaskSetup <ScriptBlock>
<TaskTearDown> ::= TaskTearDown <ScriptBlock>
<Tasks> ::= Task <TaskParameters> | <Tasks>
<TaskParameters> ::= -Name <StringLiteral> 
			| -Action <ScriptBlock> 
			| -PreAction <ScriptBlock> 
			| -PostAction <ScriptBlock> 
			| -PreCondition <ScriptBlock>
			| -PostCondition <ScriptBlock>
			| -ContinueOnError <Boolean>
			| -Depends <TaskNames>
			| -Description <StringLiteral>
<TaskNames> ::= <StringLiteral>, | <TaskNames>				
<ScriptBlock> ::= { <PowerShellStatements> }
<Boolean> ::= $true | $false
