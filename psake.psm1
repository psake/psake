# psake v0.24
# Copyright © 2009 James Kovacs
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

#-- Private Module Variables
[string]$script:originalEnvPath
[string]$script:originalDirectory
[string]$script:formatTaskNameString
[string]$script:currentTaskName
[hashtable]$script:tasks
[array]$script:properties	
[scriptblock]$script:taskSetupScriptBlock
[scriptblock]$script:taskTearDownScriptBlock
[system.collections.queue]$script:includes 
[system.collections.stack]$script:executedTasks
[system.collections.stack]$script:callStack

#-- Public Module Variables
$script:psake = @{}
Export-ModuleMember -Variable "psake"

#-- Private Module Functions
function ExecuteTask 
{
	param([string]$taskName)
	
	Assert (![string]::IsNullOrEmpty($taskName)) "Task name should not be null or empty string"
	
	$taskKey = $taskName.Tolower()
	
	Assert ($script:tasks.Contains($taskKey)) "task [$taskName] does not exist"

	if ($script:executedTasks.Contains($taskKey)) 
	{ 
		return 
	}
  
  	Assert (!$script:callStack.Contains($taskKey)) "Error: Circular reference found for task, $taskName"

	$script:callStack.Push($taskKey)
  
	$task = $script:tasks.$taskKey
	
	$taskName = $task.Name
	
	$precondition_is_valid = if ($task.Precondition -ne $null) {& $task.Precondition} else {$true}
	
	if (!$precondition_is_valid) 
	{
		"Precondition was false not executing $name"		
	}
	else
	{
		if ($taskKey -ne 'default') 
		{
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()			
			
			if ( ($task.PreAction -ne $null) -or ($task.PostAction -ne $null) )
			{
				Assert ($task.Action -ne $null) "Error: Action parameter must be specified when using PreAction or PostAction parameters"
			}
			
			if ($task.Action -ne $null) 
			{
				try
				{						
					foreach($childTask in $task.DependsOn) 
					{
						ExecuteTask $childTask
					}
					
					$script:currentTaskName = $taskName									
									
					if ($script:taskSetupScriptBlock -ne $null) 
					{
						& $script:taskSetupScriptBlock
					}
					
					if ($task.PreAction -ne $null) 
					{
						& $task.PreAction
					}
					
					$script:formatTaskNameString -f $taskName
					& $task.Action
					
					if ($task.PostAction -ne $null) 
					{
						& $task.PostAction
					}
					
					if ($script:taskTearDownScriptBlock -ne $null) 
					{
						& $script:taskTearDownScriptBlock
					}					
				}
				catch
				{
					if ($task.ContinueOnError) 
					{
						"-"*70
						"Error in Task [$taskName] $_"
						"-"*70
						continue
					} 
					else 
					{
						throw $_
					}
				}			
			} # if ($task.Action -ne $null)
			else
			{
				#no Action was specified but we still execute all the dependencies
				foreach($childTask in $task.DependsOn) 
				{
					ExecuteTask $childTask
				}
			}
			$stopwatch.stop()
			$task.Duration = $stopwatch.Elapsed
		} # if ($name.ToLower() -ne 'default') 
		else 
		{ 
			foreach($childTask in $task.DependsOn) 
			{
				ExecuteTask $childTask
			}
		}
		
		if ($task.Postcondition -ne $null) 
		{			
			Assert (& $task.Postcondition) "Error: Postcondition failed for $taskName"
		} 		
	}
	
	$poppedTaskKey = $script:callStack.Pop()
	
	Assert ($poppedTaskKey -eq $taskKey) "Error: CallStack was corrupt. Expected $taskKey, but got $poppedTaskKey."

	$script:executedTasks.Push($taskKey)
}

function Configure-BuildEnvironment 
{
	$version = $null
	switch ($framework) 
	{
		'1.0' { $version = 'v1.0.3705'  }
		'1.1' { $version = 'v1.1.4322'  }
		'2.0' { $version = 'v2.0.50727' }
		'3.0' { $version = 'v2.0.50727' } # .NET 3.0 uses the .NET 2.0 compilers
		'3.5' { $version = 'v3.5'       }
		default { throw "Error: Unknown .NET Framework version, $framework" }
	}
	$frameworkDir = "$env:windir\Microsoft.NET\Framework\$version\"
	
	Assert (test-path $frameworkDir) "Error: No .NET Framework installation directory found at $frameworkDir"

	$env:path = "$frameworkDir;$env:path"
	#if any error occurs in a PS function then "stop" processing immediately
	#	this does not effect any external programs that return a non-zero exit code 
	$global:ErrorActionPreference = "Stop"
}

function Cleanup-Environment 
{
	$env:path = $script:originalEnvPath	
	Set-Location $script:originalDirectory
	$global:ErrorActionPreference = $originalErrorActionPreference
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord=$Error[0]) 
{	
	"ErrorRecord"
	$ErrorRecord | Format-List * -Force | Out-String -Stream | ? {$_}
	""
	"ErrorRecord.InvocationInfo"
	$ErrorRecord.InvocationInfo | Format-List * | Out-String -Stream | ? {$_}
	""
	"Exception"
	$Exception = $ErrorRecord.Exception
	for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) 
	{
		"$i" * 70
		$Exception | Format-List * -Force | Out-String -Stream | ? {$_}
		""
	}
}

function Write-Documentation 
{
	$list = New-Object System.Collections.ArrayList
	foreach($key in $script:tasks.Keys) 
	{
		if($key -eq "default") 
		{
		  continue
		}
		$task = $script:tasks.$key
		$content = "" | Select-Object Name, Description
		$content.Name = $task.Name        
		$content.Description = $task.Description
		$index = $list.Add($content)
	}

	$list | Sort 'Name' | Format-Table -Auto 
}

function Write-TaskTimeSummary
{
	"-"*70
	"Build Time Report"
	"-"*70	
	$list = @()
	while ($script:executedTasks.Count -gt 0) 
	{
		$taskKey = $script:executedTasks.Pop()
		$task = $script:tasks.$taskKey
		if($taskKey -eq "default") 
		{
		  continue
		}    
		$list += "" | Select-Object @{Name="Name";Expression={$task.Name}}, @{Name="Duration";Expression={$task.Duration}}
	}
	[Array]::Reverse($list)
	$list += "" | Select-Object @{Name="Name";Expression={"Total:"}}, @{Name="Duration";Expression={$stopwatch.Elapsed}}
	$list | Format-Table -Auto | Out-String -Stream | ? {$_}  # using "Out-String -Stream" to filter out the blank line that Format-Table prepends 
}

#-- Public Module Functions
function Assert
{
<#
.Synopsis
    Helper function for "Design by Contract" assertion checking. 
.Description
    This is a helper function that makes the code less noisy by eliminating many of the "if" statements
    that are normally required to verify assumptions in the code.
.Parameter conditionToCheck 
	The boolean condition to evaluate	
	Required
.Parameter failureMessage
	The error message used for the exception if the conditionToCheck parameter is false
	Required 
.Example
	Assert $false "This always throws an exception"
    
    This example always throws an exception
.Example
    Assert (1 -eq 2) "1 doesn't equal 2"  	
    
.ReturnValue
      
.Link	
	Invoke-psake
    Task
    Properties
    Include
    FormatTaskName
    TaskSetup
    TaskTearDown
.Notes
    It might be necessary to wrap the condition with paranthesis to force PS to evaluate the condition 
    so that a boolean value is calculated and passed into the parameter.
    
    Example:
        Assert 1 -eq 2 "1 doesn't equal 2"
       
    PS will pass 1 into the condtionToCheck variable and PS will look for a parameter called "eq" and 
    throw an exception with the following message "A parameter cannot be found that matches parameter name 'eq'"
    
    The solution is to wrap the condition in () so that PS will evaluate it first.
    
        Assert (1 -eq 2) "1 doesn't equal 2"
  
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	
	param(
	  [Parameter(Position=0,Mandatory=1)]$conditionToCheck,
	  [Parameter(Position=1,Mandatory=1)]$failureMessage
	)
	if (!$conditionToCheck) { throw $failureMessage }
}

function Task
{
<#
.Synopsis
    Defines a build task to be executed by psake 
.Description
    This function contains parameters that will be used by the psake engine to execute a build task.
	Note: There must be at least one task called 'default' in the build script 
.Parameter Name 
	The name of the task	
	Required
.Parameter Action 
	A scriptblock containing the statements to execute
	Optional 
.Parameter PreAction
	A scriptblock to be executed before the 'Action' scriptblock.
	Note: This parameter is ignored if the 'Action' scriptblock is not defined.
	Optional 
.Parameter PostAction 
	A scriptblock to be executed after the 'Action' scriptblock.
	Note: This parameter is ignored if the 'Action' scriptblock is not defined.
	Optional 
.Parameter Precondition 
	A scriptblock that is executed to determine if the task is executed or skipped.
	This scriptblock should return $true or $false
	Optional
.Parameter Postcondition
	A scriptblock that is executed to determine if the task completed its job correctly.
	An exception is thrown if the scriptblock returns false.	
	Optional
.Parameter ContinueOnError
	If this switch parameter is set then the task will not cause the build to fail when an exception is thrown
.Parameter Depends
	An array of tasks that this task depends on.  They will be executed before the current task is executed.
.Parameter Description
	A description of the task.
.Example
	task default -depends Test
	
	task Test -depends Compile, Clean { 
	  $testMessage
	} 	
	
	The 'default' task is required and should not contain an 'Action' parameter.
	It uses the 'depends' parameter to specify that 'Test' is a dependency
	
	The 'Test' task uses the 'depends' parameter to specify that 'Compile' and 'Clean' are dependencies
	
	The 'Action' parameter is defaulted to the script block following the 'Clean'. 
	
	The equivalent is shown below:
	
	task Test -depends Compile, Clean -Action { 
	  $testMessage
	}
	
.ReturnValue
      
.Link	
	Invoke-psake    
    Properties
    Include
    FormatTaskName
    TaskSetup
    TaskTearDown
    Assert
.Notes
  
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
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
		[scriptblock]$precondition = $null,
		[Parameter(Position=5,Mandatory=0)]
		[scriptblock]$postcondition = $null,
		[Parameter(Position=6,Mandatory=0)]
		[switch]$continueOnError = $false, 
		[Parameter(Position=7,Mandatory=0)]
		[string[]]$depends = @(), 
		[Parameter(Position=8,Mandatory=0)]
		[string]$description = $null		
		)
	
	if ($name.ToLower() -eq 'default') 
	{
		Assert ($action -eq $null) "Error: 'default' task cannot specify an action"
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
	
	Assert (!$script:tasks.ContainsKey($taskKey)) "Error: Task, $name, has already been defined."
	
	$script:tasks.$taskKey = $newTask
}

function Properties
{
<#
.Synopsis
    Adds a scriptblock to the module varible "properies"
.Description
    A build script may declare a "Properies" function which allows you to define
	variables that will be available to all the "Task" functions in the build script.
.Parameter properties 
	The script block containing all the variable assignment statements
	Required
.Example
	Properties {
		$build_dir = "c:\build"		
		$connection_string = "datasource=localhost;initial catalog=northwind;integrated security=sspi"
	}
 
.ReturnValue
      
.Link	
	Invoke-psake    
	Task
    Include
    FormatTaskName
    TaskSetup
    TaskTearDown
    Assert	
.Notes
    You can have more than 1 "Properties" function defined in the script
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
	[Parameter(Position=0,Mandatory=1)]
	[scriptblock]$properties
	)
	$script:properties += $properties
}

function Include
{
<#
.Synopsis
    Adds a scriptblock to the module varible "includes"
.Description
    A build script may declare an "includes" function which allows you to define
	a file containing powershell code to be included and added to the scope of 
	the currently running build script.
.Parameter include 
	A string containing the path and name of the powershell file to include
	Required
.Example
	Include "c:\utils.ps1"
 
.ReturnValue
      
.Link	
	Invoke-psake    
	Task
    Properties
    FormatTaskName
    TaskSetup
    TaskTearDown
    Assert	
.Notes
    You can have more than 1 "Include" function defined in the script
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
	[Parameter(Position=0,Mandatory=1)]
	[string]$include
	)
	Assert (test-path $include) "Error: Unable to include $include. File not found."
	$script:includes.Enqueue((Resolve-Path $include));
}

function FormatTaskName 
{
<#
.Synopsis
    Allows you to define a format mask that will be used when psake displays
	the task name
.Description
    Allows you to define a format mask that will be used when psake displays
	the task name.  The default is "Executing task, {0}..."
.Parameter format 
	A string containing the format mask to use, it should contain a placeholder ({0})
	that will be used to substitute the task name.
	Required
.Example
	For the following build script:
	-------------------------------
	
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
 
.ReturnValue
      
.Link	
	Invoke-psake    
	Include
	Task
    Properties
    TaskSetup
    TaskTearDown
    Assert	
.Notes
    
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
	[Parameter(Position=0,Mandatory=1)]
	[string]$format
	)
	$script:formatTaskNameString = $format
}

function TaskSetup 
{
<#
.Synopsis
    Adds a scriptblock that will be executed before each task
.Description
    This function will accept a scriptblock that will be executed before each
	task in the build script.  
.Parameter include 
	A scriptblock to execute
	Required
.Example
	For the following build script:
	-------------------------------
	Task default -depends Test
	
	Task Test -depends Compile, Clean { 
	}
		
	Task Compile -depends Clean { 
	}
		
	Task Clean { 
	}
	
	TaskSetup {
		"Running 'TaskSetup' for task $script:currentTaskName"
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
 
.ReturnValue
      
.Link	
	Invoke-psake    
	Include
	Task
    Properties
    FormatTaskName
    TaskTearDown
    Assert	
.Notes
    
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
	[Parameter(Position=0,Mandatory=1)]
	[scriptblock]$setup
	)
	$script:taskSetupScriptBlock = $setup
}

function TaskTearDown 
{
<#
.Synopsis
    Adds a scriptblock that will be executed after each task
.Description
    This function will accept a scriptblock that will be executed after each
	task in the build script.  
.Parameter include 
	A scriptblock to execute
	Required
.Example
	For the following build script:
	-------------------------------
	Task default -depends Test
	
	Task Test -depends Compile, Clean { 
	}
		
	Task Compile -depends Clean { 
	}
		
	Task Clean { 
	}
	
	TaskTearDown {
		"Running 'TaskTearDown' for task $script:currentTaskName"
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
 
.ReturnValue
      
.Link	
	Invoke-psake    
	Include
	Task
    Properties
    FormatTaskName
    TaskSetup
    Assert	
.Notes
    
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
	[Parameter(Position=0,Mandatory=1)]
	[scriptblock]$teardown)
	$script:taskTearDownScriptBlock = $teardown
}

function Invoke-psake 
{
<#
.Synopsis
    Runs a psake build script.
.Description
    This function runs a psake build script 
.Parameter BuildFile 
	The psake build script to execute (default: default.ps1).	
.Parameter Framework 
	The version of the .NET framework you want to build
	Possible values: '1.0', '1.1', '2.0', '3.0',  '3.5'
	Default = '3.5'
.Parameter Docs 
	Prints a list of tasks and their descriptions	
	
.Example
    Invoke-psake 
	
	Runs the 'default' task in the 'default.ps1' build script in the current directory

.Example
	Invoke-psake '.\build.ps1'
	
	Runs the 'default' task in the '.build.ps1' build script

.Example
	Invoke-psake '.\build.ps1' Tests,Package
	
	Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script

.Example
	Invoke-psake '.\build.ps1' -docs
	
	Prints a report of all the tasks and their descriptions and exits
	
.ReturnValue
    No return value unless there is an exception and $psake.use_exit_on_error -eq $true
	then runs exit(1) to set the lastexitcode value in the OS
	otherwise set the $script:psake.build_success variable to $true or $false depending
	on whether an exception was thrown
	
.Link	
.Notes
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	
	param(
		[Parameter(Position=0,Mandatory=0)]
	  	[string]$buildFile = 'default.ps1',
		[Parameter(Position=1,Mandatory=0)]
	  	[string[]]$taskList = @(),
		[Parameter(Position=2,Mandatory=0)]
	  	[string]$framework = '3.5',	  
		[Parameter(Position=3,Mandatory=0)]
	  	[switch]$docs = $false	  
	)

	Begin 
	{	
		$script:psake.build_success = $false
		$script:psake.use_exit_on_error = $false
		$script:psake.log_error = $false
		$script:psake.version = "0.24"
		$script:psake.build_script_file = $null
		$script:psake.framework_version = $framework
		
		$script:formatTaskNameString = "Executing task, {0}..."
		$script:taskSetupScriptBlock = $null
		$script:taskTearDownScriptBlock = $null
		$script:executedTasks = New-Object System.Collections.Stack
		$script:callStack = New-Object System.Collections.Stack
		$script:originalEnvPath = $env:path
		$script:originalDirectory = Get-Location	
		$originalErrorActionPreference = $global:ErrorActionPreference
		
		$script:tasks = @{}
		$script:properties = @()
		$script:includes = New-Object System.Collections.Queue	
	}
	
	Process 
	{	
		try 
		{
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

			# Execute the build file to set up the tasks and defaults
			Assert (test-path $buildFile) "Error: Could not find the build file, $buildFile."
			
			$script:psake.build_script_file = dir $buildFile
			set-location $script:psake.build_script_file.Directory
			. $script:psake.build_script_file.FullName
						
			if ($docs) 
			{
				Write-Documentation
				Cleanup-Environment				
				return								
			}

			Configure-BuildEnvironment

			# N.B. The initial dot (.) indicates that variables initialized/modified
			#      in the propertyBlock are available in the parent scope.
			while ($script:includes.Count -gt 0) 
			{
				$includeBlock = $script:includes.Dequeue()
				. $includeBlock
			}
			foreach($propertyBlock in $script:properties) 
			{
				. $propertyBlock
			}		

			# Execute the list of tasks or the default task
			if($taskList.Length -ne 0) 
			{
				foreach($task in $taskList) 
				{
					ExecuteTask $task
				}
			} 
			elseif ($script:tasks.default -ne $null) 
			{
				ExecuteTask default
			} 
			else 
			{
				throw 'Error: default task required'
			}

			$stopwatch.Stop()
			
			"`nBuild Succeeded!`n" 
			
			Write-TaskTimeSummary		
			
			$script:psake.build_success = $true
		} 
		catch 
		{	
			#Append detailed exception to log file
			if ($script:psake.log_error)
			{
				$errorLogFile = "psake-error-log-{0}.log" -f ([DateTime]::Now.ToString("yyyyMMdd"))
				"-" * 70 >> $errorLogFile
				"{0}: An Error Occurred. See Error Details Below: " -f [DateTime]::Now >>$errorLogFile
				"-" * 70 >> $errorLogFile
				Resolve-Error $_ >> $errorLogFile
			}
			
            $buildFileName = Split-Path $buildFile -leaf
            if (test-path $buildFile) { $buildFileName = $script:psake.build_script_file.Name }		
			Write-Host -foregroundcolor Red ($buildFileName + ":" + $_)				
			
			if ($script:psake.use_exit_on_error) 
			{ 
				exit(1)				
			} 
			else 
			{
				$script:psake.build_success = $false
			}
		}
	} #Process
	
	End 
	{
		# Clear out any global variables
		Cleanup-Environment
	}
}

Export-ModuleMember -Function "Invoke-psake","Task","Properties","Include","FormatTaskName","TaskSetup","TaskTearDown","Assert"