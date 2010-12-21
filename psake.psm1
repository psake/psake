# psake
# Copyright (c) 2010 James Kovacs
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#Requires -Version 2.0

DATA msgs
{
convertfrom-stringdata @'
	error_invalid_task_name = Error: Task name should not be null or empty string
	error_task_name_does_not_exist = Error: task [{0}] does not exist
	error_circular_reference = Error: Circular reference found for task, {0}
	error_missing_action_parameter = Error: Action parameter must be specified when using PreAction or PostAction parameters
	error_corrupt_callstack = Error: CallStack was corrupt. Expected {0}, but got {1}.
	error_invalid_framework = Error: Invalid .NET Framework version, {0}, specified
	error_unknown_framework = Error: Unknown .NET Framework version, {0}, specified in {1}
	error_unknown_pointersize = Error: Unknown pointer size ({0}) returned from System.IntPtr.
	error_unknown_bitnesspart = Error: Unknown .NET Framework bitness, {0}, specified in {1}
	error_no_framework_install_dir_found = Error: No .NET Framework installation directory found at {0}
	error_bad_command = Error executing command: {0}
	error_default_task_cannot_have_action = Error: 'default' task cannot specify an action
	error_duplicate_task_name = Error: Task {0} has already been defined.
	error_invalid_include_path = Error: Unable to include {0}. File not found.
	error_build_file_not_found = Error: Could not find the build file, {0}.
	error_no_default_task = Error: default task required
	error_invalid_module_dir = "Unable to load modules from directory: {0}"
	error_invalid_module_path = "Unable to load module at path: {0}"
	error_loading_module = "Error loading module: {0}"
	postcondition_failed = Error: Postcondition failed for {0}
	precondition_was_false = Precondition was false not executing {0}
	continue_on_error = Error in Task [{0}] {1}
	build_success = Build Succeeded!
'@
} 

import-localizeddata -bindingvariable msgs -erroraction silentlycontinue

#-- Private Module Functions
function Load-Configuration
{
	$psake.config = new-object psobject -property @{
	  defaultbuildfilename="default.ps1";
	  tasknameformat="Executing {0}";
	  exitcode="1";
	  modules=(new-object psobject -property @{ autoload=$false })
	}
		
	$psakeConfigFilePath = (join-path $PSScriptRoot psake-config.ps1)
	
	if (test-path $psakeConfigFilePath)
	{
		try
		{
			. $psakeConfigFilePath
		}
		catch
		{
			throw "Error Loading Configuration from psake-config.ps1: " + $_
		}
	}
}

function IsChildOfService
{
    param
    (                             
    [int]$currentProcessID = $PID
    ) 

    $currentProcess = gwmi -Query "select * from win32_process where processid = '$currentProcessID'"

    if ($currentProcess.ProcessID -eq 0)  #System Idle Process
    {
       return $false
    }
	
	$service = Get-WmiObject -Class Win32_Service -Filter "ProcessId = '$currentProcessID'"

	if ($service) # We are invoked by a windows service
	{
		return $true
	}
	else
	{	
		$parentProcess = gwmi -Query "select * from win32_process where processid = '$($currentProcess.ParentProcessID)'"
		return IsChildOfService $parentProcess.ProcessID
	}
}

function InNestedScope
{
	try
	{
		$vars = get-variable -scope 1
		return $true
	}
	catch 
	{
		return $false
	}
}

function Configure-BuildEnvironment
{
  if ($framework.Length -ne 3 -and $framework.Length -ne 6) {    
    throw ($msgs.error_invalid_framework -f $framework)
  }
  $versionPart = $framework.Substring(0,3)
  $bitnessPart = $framework.Substring(3)
  $versions = $null
  switch ($versionPart)
  {
    '1.0' { $versions = @('v1.0.3705')  }
    '1.1' { $versions = @('v1.1.4322')  }
    '2.0' { $versions = @('v2.0.50727') }
    '3.0' { $versions = @('v2.0.50727') }
    '3.5' { $versions = @('v3.5','v2.0.50727') }
    '4.0' { $versions = @('v4.0.30319') }
    default { throw ($msgs.error_unknown_framework -f $versionPart,$framework) }
  }

  $bitness = 'Framework'
  if($versionPart -ne '1.0' -and $versionPart -ne '1.1') {
    switch ($bitnessPart)
    {
      'x86' { $bitness = 'Framework' }
      'x64' { $bitness = 'Framework64' }
      $null {
        $ptrSize = [System.IntPtr]::Size
        switch ($ptrSize)
        {
          4 { $bitness = 'Framework' }
          8 { $bitness = 'Framework64' }
          default { throw ($msgs.error_unknown_pointersize -f $ptrSize) }
        }
      }
      default { throw ($msgs.error_unknown_bitnesspart -f $bitnessPart,$framework) }
    }
  }
  $frameworkDirs = $versions | foreach { "$env:windir\Microsoft.NET\$bitness\$_\" }

  $frameworkDirs | foreach { Assert (test-path $_) ($msgs.error_no_framework_install_dir_found -f $_)}

  $env:path = ($frameworkDirs -join ";") + ";$env:path"
  #if any error occurs in a PS function then "stop" processing immediately
  # this does not effect any external programs that return a non-zero exit code
  $global:ErrorActionPreference = "Stop"
}

function Cleanup-Environment
{
	if ($psake.context.Count -gt 0)
	{
		$currentContext = $psake.context.Peek()
		$env:path = $currentContext.originalEnvPath
		Set-Location $currentContext.originalDirectory
		$global:ErrorActionPreference = $currentContext.originalErrorActionPreference
		[void]$psake.context.Pop()
	}
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord=$Error[0])
{
	$error_message = "`nErrorRecord:{0}ErrorRecord.InvocationInfo:{1}Exception:{2}"
	$formatted_errorRecord = $ErrorRecord | format-list * -force | out-string 
	$formatted_invocationInfo = $ErrorRecord.InvocationInfo | format-list * -force | out-string 
	$formatted_exception = ""
	$Exception = $ErrorRecord.Exception
	for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
	{
		$formatted_exception += ("$i" * 70) + "`n"
		$formatted_exception += $Exception | format-list * -force | out-string
		$formatted_exception += "`n"
	}
	
	return $error_message -f $formatted_errorRecord,$formatted_invocationInfo,$formatted_exception
}

function Write-Documentation
{
	$currentContext = $psake.context.Peek()
	$currentContext.tasks.Keys | 
	foreach-object { 
	if($_ -eq "default") { return }

	$task = $currentContext.tasks.$_
	new-object PsObject -property @{
		Name         = $task.Name
		Description  = $task.Description
		"Depends On" = $task.DependsOn -join ", "
		}
	} |
	Sort 'Name' | 
	Format-Table -Auto
}

function Write-TaskTimeSummary
{
	"-"*70
	"Build Time Report"
	"-"*70
	$list = @()
	$currentContext = $psake.context.Peek()
	while ($currentContext.executedTasks.Count -gt 0)
	{
		$taskKey = $currentContext.executedTasks.Pop()
		$task = $currentContext.tasks.$taskKey
		if($taskKey -eq "default")
		{
		  continue
		}
		$list += New-Object PsObject -property @{Name=$task.Name; Duration = $task.Duration}
	}
	[Array]::Reverse($list)
	$list += New-Object PsObject -property @{Name="Total:"; Duration=$stopwatch.Elapsed}
	$list | Format-Table -Auto | Out-String -Stream | ? {$_}  # using "Out-String -Stream" to filter out the blank line that Format-Table prepends
}

#-- Public Module Functions
function Invoke-Task
{
<#
.SYNOPSIS
This function allows you to call a target from another target

.DESCRIPTION
This is a function that will allow you to invoke a function from within another function

.PARAMETER taskName
The name of the task to execute

.EXAMPLE
invoke-task clean

This example calls "clean" task

.LINK
Assert
Invoke-psake
Task
Properties
Include
FormatTaskName
TaskSetup
TaskTearDown
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)][string]$taskName)
	
	Assert $taskName ($msgs.error_invalid_task_name)

	$taskKey = $taskName.ToLower()

	$currentContext = $psake.context.Peek()
	$tasks = $currentContext.tasks
	$executedTasks = $currentContext.executedTasks
	$callStack = $currentContext.callStack

	Assert ($tasks.Contains($taskKey)) ($msgs.error_task_name_does_not_exist -f $taskName)

	if ($executedTasks.Contains($taskKey))  { return }

	Assert (!$callStack.Contains($taskKey)) ($msgs.error_circular_reference -f $taskName)

	$callStack.Push($taskKey)

	$task = $tasks.$taskKey

	$precondition_is_valid = & $task.Precondition

	if (!$precondition_is_valid)
	{
		$msgs.precondition_was_false -f $taskName
	}
	else
	{
		if ($taskKey -ne 'default')
		{
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

			if ($task.PreAction -or $task.PostAction)
			{
				Assert ($task.Action -ne $null) $msgs.error_missing_action_parameter
			}

			if ($task.Action)
			{
				try
				{
					foreach($childTask in $task.DependsOn)
					{
						Invoke-Task $childTask
					}

					$currentContext.currentTaskName = $taskName

					& $currentContext.taskSetupScriptBlock

					if ($task.PreAction)
					{
						& $task.PreAction
					}

					if ($currentContext.formatTaskName -is [ScriptBlock])
					{
						& $currentContext.formatTaskName $taskName
					}
					else
					{
						$currentContext.formatTaskName -f $taskName
					}

					& $task.Action 

					if ($task.PostAction)
					{
						& $task.PostAction
					}

					& $currentContext.taskTearDownScriptBlock
				}
				catch
				{
					if ($task.ContinueOnError)
					{
						"-"*70            
						$msgs.continue_on_error -f $taskName,$_
						"-"*70
					}
					else
					{
						throw $_
					}
				}
			} # if ($task.Action)
			else
			{
				#no Action was specified but we still execute all the dependencies
				foreach($childTask in $task.DependsOn)
				{
					Invoke-Task $childTask
				}
			}
			$stopwatch.stop()
			$task.Duration = $stopwatch.Elapsed
		} # if ($taskKey -ne 'default')
		else
		{
			foreach($childTask in $task.DependsOn)
			{
				Invoke-Task $childTask
			}
		}

		Assert (& $task.Postcondition) ($msgs.postcondition_failed -f $taskName)
	}

	$poppedTaskKey = $callStack.Pop()
	Assert ($poppedTaskKey -eq $taskKey) ($msgs.error_corrupt_callstack -f $taskKey,$poppedTaskKey)

	$executedTasks.Push($taskKey)
}

function Exec
{
<#
.SYNOPSIS
Helper function for executing command-line programs.

.DESCRIPTION
This is a helper function that runs a scriptblock and checks the PS variable $lastexitcode to see if an error occcured.
If an error is detected then an exception is thrown.  This function allows you to run command-line programs without
having to explicitly check fthe $lastexitcode variable.

.PARAMETER cmd
The scriptblock to execute.  This scriptblock will typically contain the command-line invocation.
Required

.PARAMETER errorMessage
The error message used for the exception that is thrown.
Optional

.EXAMPLE
exec { svn info $repository_trunk } "Error executing SVN. Please verify SVN command-line client is installed"

This example calls the svn command-line client.

.LINK
Assert
Invoke-psake
Task
Properties
Include
FormatTaskName
TaskSetup
TaskTearDown
#>
  [CmdletBinding()]

	param(
		[Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
		[Parameter(Position=1,Mandatory=0)][string]$errorMessage = ($msgs.error_bad_command -f $cmd)
	)
	& $cmd
	if ($lastexitcode -ne 0)
	{
		throw $errorMessage
	}
}

function Assert
{
<#
.SYNOPSIS
Helper function for "Design by Contract" assertion checking.

.DESCRIPTION
This is a helper function that makes the code less noisy by eliminating many of the "if" statements
that are normally required to verify assumptions in the code.

.PARAMETER conditionToCheck
The boolean condition to evaluate
Required

.PARAMETER failureMessage
The error message used for the exception if the conditionToCheck parameter is false
Required

.EXAMPLE
Assert $false "This always throws an exception"

This example always throws an exception

.EXAMPLE
Assert ( ($i % 2) -eq 0 ) "%i is not an even number"

This exmaple may throw an exception if $i is not an even number

.LINK
Invoke-psake
Task
Properties
Include
FormatTaskName
TaskSetup
TaskTearDown

.NOTES
It might be necessary to wrap the condition with paranthesis to force PS to evaluate the condition
so that a boolean value is calculated and passed into the 'conditionToCheck' parameter.

Example:
    Assert 1 -eq 2 "1 doesn't equal 2"

PS will pass 1 into the condtionToCheck variable and PS will look for a parameter called "eq" and
throw an exception with the following message "A parameter cannot be found that matches parameter name 'eq'"

The solution is to wrap the condition in () so that PS will evaluate it first.

    Assert (1 -eq 2) "1 doesn't equal 2"
#>
  [CmdletBinding()]

	param(
		[Parameter(Position=0,Mandatory=1)]$conditionToCheck,
		[Parameter(Position=1,Mandatory=1)]$failureMessage
	)
	if (!$conditionToCheck)
	{
		if ($failureMessage.GetType() -eq [String]) {
			$failureMessage = "[[ASSERTTEXTONLY]]" + $failureMessage
		}

		throw $failureMessage 
	}
}

function Task
{
<#
.SYNOPSIS
Defines a build task to be executed by psake

.DESCRIPTION
This function creates a 'task' object that will be used by the psake engine to execute a build task.
Note: There must be at least one task called 'default' in the build script

.PARAMETER Name
The name of the task
Required

.PARAMETER Action
A scriptblock containing the statements to execute
Optional

.PARAMETER PreAction
A scriptblock to be executed before the 'Action' scriptblock.
Note: This parameter is ignored if the 'Action' scriptblock is not defined.
Optional

.PARAMETER PostAction
A scriptblock to be executed after the 'Action' scriptblock.
Note: This parameter is ignored if the 'Action' scriptblock is not defined.
Optional

.PARAMETER Precondition
A scriptblock that is executed to determine if the task is executed or skipped.
This scriptblock should return $true or $false
Optional

.PARAMETER Postcondition
A scriptblock that is executed to determine if the task completed its job correctly.
An exception is thrown if the scriptblock returns $false.
Optional

.PARAMETER ContinueOnError
If this switch parameter is set then the task will not cause the build to fail when an exception is thrown

.PARAMETER Depends
An array of tasks that this task depends on.  They will be executed before the current task is executed.

.PARAMETER Description
A description of the task.

.EXAMPLE
A sample build script is shown below:

task default -depends Test

task Test -depends Compile, Clean {
  "This is a test"
}

task Compile -depends Clean {
  "Compile"
}

task Clean {
  "Clean"
}

The 'default' task is required and should not contain an 'Action' parameter.
It uses the 'depends' parameter to specify that 'Test' is a dependency

The 'Test' task uses the 'depends' parameter to specify that 'Compile' and 'Clean' are dependencies
The 'Compile' task depends on the 'Clean' task.

Note:
The 'Action' parameter is defaulted to the script block following the 'Clean' task.

The equivalent 'Test' task is shown below:

task Test -depends Compile, Clean -Action {
  $testMessage
}

The output for the above sample build script is shown below:
Executing task, Clean...
Clean
Executing task, Compile...
Compile
Executing task, Test...
This is a test

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0065614
Compile 00:00:00.0133268
Test    00:00:00.0225964
Total:  00:00:00.0782496

.LINK
Invoke-psake
Properties
Include
FormatTaskName
TaskSetup
TaskTearDown
Assert
#>
  [CmdletBinding()]
  
  param(
    [Parameter(Position=0,Mandatory=1)]
    [string]$name = $null,
	
    [Parameter(Position=1,Mandatory=0)]
    [scriptblock]$action = $null,
    
	[Parameter(Position=2,Mandatory=0)]
    [scriptblock]$preaction = $null,
    
	[Parameter(Position=3,Mandatory=0)]
    [scriptblock]$postaction = $null,
    
	[Parameter(Position=4,Mandatory=0)]
    [scriptblock]$precondition = {$true},
    
	[Parameter(Position=5,Mandatory=0)]
    [scriptblock]$postcondition = {$true},
    
	[Parameter(Position=6,Mandatory=0)]
    [switch]$continueOnError = $false,
    
	[Parameter(Position=7,Mandatory=0)]
    [string[]]$depends = @(),
    
	[Parameter(Position=8,Mandatory=0)]
    [string]$description = $null
    )

	if ($name -eq 'default')
	{
		Assert (!$action) ($msgs.error_default_task_cannot_have_action)
	}

	$newTask = @{
		Name = $name
		DependsOn = $depends
		PreAction = $preaction
		Action = $action
		PostAction = $postaction
		Precondition = $precondition
		Postcondition = $postcondition
		ContinueOnError = $continueOnError
		Description = $description
		Duration = 0	
	}

	$taskKey = $name.ToLower()
	
	$currentContext = $psake.context.Peek()

	Assert (!$currentContext.tasks.ContainsKey($taskKey)) ($msgs.error_duplicate_task_name -f $name) 

	$currentContext.tasks.$taskKey = $newTask
}

function Properties
{
<#
.SYNOPSIS
Define a scriptblock that contains assignments to variables that will be available to all tasks in the build script

.DESCRIPTION
A build script may declare a "Properies" function which allows you to define
variables that will be available to all the "Task" functions in the build script.

.PARAMETER properties
The script block containing all the variable assignment statements
Required

.EXAMPLE
A sample build script is shown below:

Properties {
  $build_dir = "c:\build"
  $connection_string = "datasource=localhost;initial catalog=northwind;integrated security=sspi"
}

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

.LINK
Invoke-psake
Task
Include
FormatTaskName
TaskSetup
TaskTearDown
Assert

.NOTES
You can have more than 1 "Properties" function defined in the script
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)][scriptblock]$properties)	
	$psake.context.Peek().properties += $properties
}

function Include
{
<#
.SYNOPSIS
Include the functions or code of another powershell script file into the current build script's scope

.DESCRIPTION
A build script may declare an "includes" function which allows you to define
a file containing powershell code to be included and added to the scope of
the currently running build script.

.PARAMETER fileNamePathToInclude
A string containing the path and name of the powershell file to include
Required

.EXAMPLE
A sample build script is shown below:

Include ".\build_utils.ps1"

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}


.LINK
Invoke-psake
Task
Properties
FormatTaskName
TaskSetup
TaskTearDown
Assert

.NOTES
You can have more than 1 "Include" function defined in the script
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)][string]$fileNamePathToInclude)
	Assert (test-path $fileNamePathToInclude) ($msgs.error_invalid_include_path -f $fileNamePathToInclude)
	$psake.context.Peek().includes.Enqueue((Resolve-Path $fileNamePathToInclude));
}

function FormatTaskName
{
<#
.SYNOPSIS
Allows you to define a format mask that will be used when psake displays
the task name

.DESCRIPTION
Allows you to define a format mask that will be used when psake displays
the task name.  The default is "Executing task, {0}..."

.PARAMETER format
A string containing the format mask to use, it should contain a placeholder ({0})
that will be used to substitute the task name.
Required

.EXAMPLE
A sample build script is shown below:

FormatTaskName "[Task: {0}]"

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

You should get the following output:
------------------------------------

[Task: Clean]
[Task: Compile]
[Task: Test]

Build Succeeded

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0043477
Compile 00:00:00.0102130
Test    00:00:00.0182858
Total:  00:00:00.0698071

.LINK
Invoke-psake
Include
Task
Properties
TaskSetup
TaskTearDown
Assert
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)]$format)
	$psake.context.Peek().formatTaskName = $format
}

function TaskSetup
{
<#
.SYNOPSIS
Adds a scriptblock that will be executed before each task

.DESCRIPTION
This function will accept a scriptblock that will be executed before each
task in the build script.

.PARAMETER include
A scriptblock to execute
Required

.EXAMPLE
A sample build script is shown below:

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

TaskSetup {
  "Running 'TaskSetup' for task $context.Peek().currentTaskName"
}

You should get the following output:
------------------------------------

Running 'TaskSetup' for task Clean
Executing task, Clean...
Running 'TaskSetup' for task Compile
Executing task, Compile...
Running 'TaskSetup' for task Test
Executing task, Test...

Build Succeeded

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0054018
Compile 00:00:00.0123085
Test    00:00:00.0236915
Total:  00:00:00.0739437

.LINK
Invoke-psake
Include
Task
Properties
FormatTaskName
TaskTearDown
Assert
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)][scriptblock]$setup)
	$psake.context.Peek().taskSetupScriptBlock = $setup
}

function TaskTearDown
{
<#
.SYNOPSIS
Adds a scriptblock that will be executed after each task

.DESCRIPTION
This function will accept a scriptblock that will be executed after each
task in the build script.

.PARAMETER include
A scriptblock to execute
Required

.EXAMPLE
A sample build script is shown below:

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

TaskTearDown {
  "Running 'TaskTearDown' for task $context.Peek().currentTaskName"
}

You should get the following output:
------------------------------------

Executing task, Clean...
Running 'TaskTearDown' for task Clean
Executing task, Compile...
Running 'TaskTearDown' for task Compile
Executing task, Test...
Running 'TaskTearDown' for task Test

Build Succeeded

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0064555
Compile 00:00:00.0218902
Test    00:00:00.0309151
Total:  00:00:00.0858301

.LINK
Invoke-psake
Include
Task
Properties
FormatTaskName
TaskSetup
Assert
#>
	[CmdletBinding()]
	param([Parameter(Position=0,Mandatory=1)][scriptblock]$teardown)
	$psake.context.Peek().taskTearDownScriptBlock = $teardown
}

function Invoke-psake
{
<#
.SYNOPSIS
Runs a psake build script.

.DESCRIPTION
This function runs a psake build script

.PARAMETER BuildFile
The psake build script to execute (default: default.ps1).

.PARAMETER TaskList
A comma-separated list of task names to execute

.PARAMETER Framework
The version of the .NET framework you want to build. You can append x86 or x64 to force a specific framework. If not specified, x86 or x64 will be detected based on the bitness of the PowerShell process.
Possible values: '1.0', '1.1', '2.0', '2.0x86', '2.0x64', '3.0', '3.0x86', '3.0x64', '3.5', '3.5x86', '3.5x64', '4.0', '4.0x86', '4.0x64'
Default = '3.5'

.PARAMETER Docs
Prints a list of tasks and their descriptions

.PARAMETER Parameters
A hashtable containing parameters to be passed into the current build script.  These parameters will be processed before the 'Properties' function of the script is processed.  This means you can access parameters from within the 'Properties' function!

.PARAMETER Properties
A hashtable containing properties to be passed into the current build script.  These properties will override matching properties that are found in the 'Properties' function of the script.

.EXAMPLE
Invoke-psake

Runs the 'default' task in the 'default.ps1' build script in the current directory

.EXAMPLE
Invoke-psake '.\build.ps1'

Runs the 'default' task in the '.build.ps1' build script

.EXAMPLE
Invoke-psake '.\build.ps1' Tests,Package

Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script

.EXAMPLE
Invoke-psake Tests

If you have your Tasks in the .\default.ps1. This example will run the 'Tests' tasks in the 'default.ps1' build script.

.EXAMPLE
Invoke-psake 'Tests, Package'

If you have your Tasks in the .\default.ps1. This example will run the 'Tests' and 'Package' tasks in the 'default.ps1' build script.
NOTE: the quotes around the list of tasks to execute.

.EXAMPLE
Invoke-psake '.\build.ps1' -docs

Prints a report of all the tasks and their descriptions and exits

.EXAMPLE
Invoke-psake .\parameters.ps1 -parameters @{"p1"="v1";"p2"="v2"}

Runs the build script called 'parameters.ps1' and passes in parameters 'p1' and 'p2' with values 'v1' and 'v2'

.EXAMPLE
Invoke-psake .\properties.ps1 -properties @{"x"="1";"y"="2"}

Runs the build script called 'properties.ps1' and passes in parameters 'x' and 'y' with values '1' and '2'

.OUTPUTS
  If there is an exception and the build script was invoked by a windows service (directly/indirectly)
  then runs exit(1) to set the DOS lastexitcode variable
  otherwise set the '$psake.build_success variable' to $true or $false depending
  on whether an exception was thrown

.NOTES
When the psake module is loaded a variabled called $psake is created it is a hashtable
containing some variables that can be used to configure psake:

$psake.build_success = $false       # indicates that the current build was successful
$psake.version = "4.00"             # contains the current version of psake
$psake.build_script_file = $null    # contains a System.IO.FileInfo for the current build file
$psake.build_script_dir				# contains the fully qualified path to the current build file
$psake.framework_version = ""       # contains the framework version # for the current build

You should see the following when you display the contents of the $psake variable right after importing psake

PS projects:\psake> Import-Module .\psake.psm1
PS projects:\psake> $psake

Name                           Value
----                           -----
version                        4.00
build_script_file
build_script_dir
build_success                  False
framework_version

After a build is executed the following $psake values are updated (build_script_file, build_script_dir, build_success, and framework_version)

PS projects:\psake> Invoke-psake .\examples\default.ps1
Executing task: Clean
Executed Clean!
Executing task: Compile
Executed Compile!
Executing task: Test
Executed Test!

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0798486
Compile 00:00:00.0869948
Test    00:00:00.0958225
Total:  00:00:00.2712414

PS projects:\psake> $psake

Name                           Value
----                           -----
version                        4.00
build_script_file              C:\Users\Jorge\Documents\Projects\psake\examples\default.ps1
build_script_dir			   C:\Users\Jorge\Documents\Projects\psake\examples	
build_success                  True
framework_version              3.5

.LINK
Task
Include
Properties
FormatTaskName
TaskSetup
TaskTearDown
Assert
#>
	[CmdletBinding()]
	param(
		[Parameter(Position=0,Mandatory=0)]
		[string]$buildFile = $psake.config.defaultbuildfilename,
		[Parameter(Position=1,Mandatory=0)]
		[string[]]$taskList = @(),
		[Parameter(Position=2,Mandatory=0)]
		[string]$framework = '3.5',
		[Parameter(Position=3,Mandatory=0)]
		[switch]$docs = $false,
		[Parameter(Position=4,Mandatory=0)]
		[hashtable]$parameters = @{},
		[Parameter(Position=5, Mandatory=0)]
		[hashtable]$properties = @{}
	)

	try
	{
		$psake.build_success = $false
		$psake.framework_version = $framework

		$psake.context.push(@{
		   "formatTaskName" = $psake.config.tasknameformat;
		   "taskSetupScriptBlock" = {};
		   "taskTearDownScriptBlock" = {};
		   "executedTasks" = New-Object System.Collections.Stack;
		   "callStack" = New-Object System.Collections.Stack;
		   "originalEnvPath" = $env:path;
		   "originalDirectory" = Get-Location;
		   "originalErrorActionPreference" = $global:ErrorActionPreference;
		   "tasks" = @{};
		   "properties" = @();
		   "includes" = New-Object System.Collections.Queue;
		})
		
		$currentContext = $psake.context.Peek()
		
		$modules = $null

		if ($psake.config.modules.autoload -eq $true)
		{
			if ($psake.config.modules.directory)
			{
				Assert (test-path $psake.config.modules.directory) ($msgs.error_invalid_module_dir -f $psake.config.modules.directory)
				$modules = get-item (join-path $psake.config.modules.directory *.psm1)
			}
			elseif (test-path (join-path $PSScriptRoot "modules"))
			{
				$modules = get-item (join-path (join-path $PSScriptRoot "modules") "*.psm1")
			}
		}
		else
		{
			if ($psake.config.modules.module)
			{
				$modules = $psake.config.modules.module | % { Assert (test-path $_.path) ($msgs.error_invalid_module_path -f $_.path); get-item $_.path }
			}
		}
		
		if ($modules)
		{
			$modules | % { "loading module: $_"; $module = import-module $_ -passthru; if (!$module) { throw ($msgs.error_loading_module -f $_.Name)} }
			""
		}
		
		$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()	
		
		<#
		If the default.ps1 file exists and the given "buildfile" isn't found assume that the given 
		$buildFile is actually the target Tasks to execute in the default.ps1 script.
		#>
		if ((Test-Path $psake.config.defaultbuildfilename ) -and !(test-path $buildFile)) 
		{     
			$taskList = $buildFile.Split(',')
			$buildFile = $psake.config.defaultbuildfilename
		}

		# Execute the build file to set up the tasks and defaults
		Assert (test-path $buildFile) ($msgs.error_build_file_not_found -f $buildFile)

		$psake.build_script_file = Get-Item $buildFile
		$psake.build_script_dir = $psake.build_script_file.DirectoryName
		set-location $psake.build_script_dir
		. $psake.build_script_file.FullName

		if ($docs)
		{
			Write-Documentation
			Cleanup-Environment
			return
		}

		Configure-BuildEnvironment
		
		# N.B. The initial dot (.) indicates that variables initialized/modified
		#      in the propertyBlock are available in the parent scope.
		while ($currentContext.includes.Count -gt 0)
		{
			$includeBlock = $currentContext.includes.Dequeue()
			. $includeBlock
		}

		foreach($key in $parameters.keys)
		{
			if (test-path "variable:\$key")
			{
				set-item -path "variable:\$key" -value $parameters.$key | out-null
			}
			else
			{
				new-item -path "variable:\$key" -value $parameters.$key | out-null
			}
		}

		foreach($propertyBlock in $currentContext.properties)
		{
			. $propertyBlock
		}

		foreach($key in $properties.keys)
		{
			if (test-path "variable:\$key")
			{
				set-item -path "variable:\$key" -value $properties.$key | out-null
			}
		}

		# Execute the list of tasks or the default task
		if($taskList)
		{
			foreach($task in $taskList)
			{
				invoke-task $task
			}
		}
		elseif ($currentContext.tasks.default)
		{
			invoke-task default
		}
		else
		{
			throw $msgs.error_no_default_task
		}

		$stopwatch.Stop()

		"`n" + $msgs.build_success + "`n"

		Write-TaskTimeSummary

		$psake.build_success = $true
    }
    catch
    {
		if ($_.TargetObject.GetType() -eq [String] -and $_.TargetObject.StartsWith("[[ASSERTTEXTONLY]]")) {

			$error_message = "{0}: An Assertion Failed.  Message: " -f (Get-Date) + $_.TargetObject.SubString("[[ASSERTTEXTONLY]]".length)

		} else {
	  	    $error_message = "{0}: An Error Occurred. See Error Details Below: `n" -f (Get-Date) 
			$error_message += ("-" * 70) + "`n"
			$error_message += Resolve-Error $_
			$error_message += ("-" * 70) + "`n"
			$error_message += "Script Variables" + "`n"
			$error_message += ("-" * 70) + "`n"
			$error_message += get-variable -scope script | format-table | out-string 
		}
		
		$psake.build_success = $false
		
		if (!$psake.run_by_psake_build_tester)
		{
			write-host $error_message -foregroundcolor red

			# Need to return a non-zero DOS exit code so that CI server's (Hudson, TeamCity, etc...) can detect a failed job
			if ( (IsChildOfService) )
			{
				exit($psake.config.exitcode)
			}
						
			#if we are running in a nested scope then we need to re-throw the exception
			if ( (InNestedScope) )
			{
				throw $_
			}
		}
    }
	finally
	{    
		Cleanup-Environment    
	}
}

$script:psake = @{}
$psake.build_success = $false        			# indicates that the current build was successful
$psake.version = "4.00"              			# contains the current version of psake
$psake.build_script_file = $null     			# contains a System.IO.FileInfo for the current build file
$psake.build_script_dir = ""  				   	# contains a string with fully-qualified path to current build script
$psake.framework_version = ""        			# contains the framework version # for the current build
$psake.run_by_psake_build_tester = $false		# indicates that build is being run by psake-BuildTester
$psake.context = new-object system.collections.stack # holds onto the current state of all variables

Load-Configuration

export-modulemember -function invoke-psake, invoke-task, task, properties, include, formattaskname, tasksetup, taskteardown, assert, exec -variable psake
