# psake v0.23
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

#-- Start Exported Functions
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
	
	This is the 'default' task and should not contain an 'Action' parameter.
	Uses the 'depends' parameter to specify that 'Test' is a dependency

.Example
	task Test -depends Compile, Clean { 
	  $testMessage
	} 	
	
	This task uses the 'depends' parameter to specify that 'Compile' and 'Clean' are dependencies
	
	The 'Action' parameter is defaulted to the script block following the 'Clean'. 
	The equivalen is shown below:
	
	task Test -depends Compile, Clean -Action { 
	  $testMessage
	}
	
.ReturnValue
      
.Link	
	Run-psake
.Notes
 NAME:      Run-psake
 AUTHOR:    Jorge Matos
 LASTEDIT:  05/12/2009
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	param(
		[string]$name = $null, 
		[scriptblock]$action = $null, 
		[scriptblock]$preaction = $null,
		[scriptblock]$postaction = $null,
		[scriptblock]$precondition = $null, 
		[scriptblock]$postcondition = $null, 
		[switch]$continueOnError = $false, 
		[string[]]$depends = @(), 
		[string]$description = $null
		)
	if ([string]::IsNullOrEmpty($name)) 
	{
		throw "Error: Task must have a name"	
	}
	if (($name.ToLower() -eq 'default') -and ($action -ne $null)) 
	{
		throw "Error: Default task cannot specify an action"
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
	if ($global:tasks.$name -ne $null) 
	{ 
		throw "Error: Task, $name, has already been defined." 
	}
	$global:tasks.$name = $newTask
}

function Properties
{
	param([scriptblock]$propertyBlock)
	$global:properties += $propertyBlock
}

function Include
{
	param([string]$include)
	if (!(test-path $include)) 
	{ 
		throw "Error: $include not found."
	} 	
	$global:includes.Enqueue((Resolve-Path $include));
}

function FormatTaskName 
{
	param([string]$format)
	$global:formatTaskNameString = $format
}

function TaskSetup 
{
	param([scriptblock]$setup)
	$global:taskSetupScriptBlock = $setup
}

function TaskTearDown 
{
	param([scriptblock]$teardown)
	$global:taskTearDownScriptBlock = $teardown
}
#-- END Exported Functions

function ExecuteTask 
{
	param([string]$name)
	
	if (!$global:tasks.Contains($name)) 
	{
		throw "task [$name] does not exist"
	}

	if ($global:executedTasks.Contains($name)) 
	{ 
		return 
	}
  
	if ($global:callStack.Contains($name)) 
	{
		throw "Error: Circular reference found for task, $name"
	}
  
	$global:callStack.Push($name)
  
	$task = $global:tasks.$name
	
	$precondition_is_valid = if ($task.Precondition -ne $null) {& $task.Precondition} else {$true}
	
	if (!$precondition_is_valid) 
	{
		"Precondition was false not executing $name"		
	}
	else
	{
		if ($name.ToLower() -ne 'default') 
		{
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
			
			if ( ($task.PreAction -ne $null) -or ($task.PostAction -ne $null) -and ($task.Action -eq $null) )
			{
				throw "Error: Action must be specified when using PreAction or PostAction parameters"
			}
			
			if ($task.Action -ne $null) 
			{
				try
				{						
					foreach($childTask in $task.DependsOn) 
					{
						ExecuteTask $childTask
					}
					
					if ($global:formatTaskNameString -ne $null) 
					{
						$global:formatTaskNameString -f $name
					} 
					else 
					{	
						"Executing task, $name..."
					}
					
					if ($global:taskSetupScriptBlock -ne $null) 
					{
						& $global:taskSetupScriptBlock
					}
					
					if ($task.PreAction -ne $null) 
					{
						& $task.PreAction
					}
					
					& $task.Action
					
					if ($task.PostAction -ne $null) 
					{
						& $task.PostAction
					}
					
					if ($global:taskTearDownScriptBlock -ne $null) 
					{
						& $global:taskTearDownScriptBlock
					}					
				}
				catch
				{
					if ($task.ContinueOnError) 
					{
						"-"*70
						"Error in Task [$name] $_"
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
		
		$postcondition = if ($task.Postcondition -ne $null) {(& $task.Postcondition)} else {$true} 
					
		if (!$postcondition) 
		{
			throw "Error: Postcondition failed for $name"
		}
	}
	
	$poppedTask = $global:callStack.Pop()
	if($poppedTask -ne $name) 
	{
		throw "Error: CallStack was corrupt. Expected $name, but got $poppedTask."
	}
	$global:executedTasks.Push($name)
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
	if(!(test-path $frameworkDir)) 
	{
		throw "Error: No .NET Framework installation directory found at $frameworkDir"
	}
	$env:path = "$frameworkDir;$env:path"
	$global:ErrorActionPreference = "Stop"
}

function Cleanup-Environment 
{
	$env:path = $global:originalEnvPath	
	Set-Location $global:originalDirectory
	$global:ErrorActionPreference = $originalErrorActionPreference
	remove-variable tasks -scope "global" -ErrorAction SilentlyContinue
	remove-variable properties -scope "global" -ErrorAction SilentlyContinue
	remove-variable includes -scope "global" -ErrorAction SilentlyContinue
	remove-variable psake_version -scope "global" -ErrorAction SilentlyContinue 
	remove-variable psake_buildScript -scope "global" -ErrorAction SilentlyContinue 
	remove-variable formatTaskNameString -scope "global" -ErrorAction SilentlyContinue 
	remove-variable taskSetupScriptBlock -scope "global" -ErrorAction SilentlyContinue 
	remove-variable taskTearDownScriptBlock -scope "global" -ErrorAction SilentlyContinue 
	remove-variable psake_frameworkVersion -scope "global" -ErrorAction SilentlyContinue 
	if (!$noexit) 
	{
		remove-variable psake_buildSucceeded -scope "global" -ErrorAction SilentlyContinue 
	}  
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord=$Error[0]) 
{	
	$ErrorRecord | Format-List * -Force
	$ErrorRecord.InvocationInfo | Format-List *
	$Exception = $ErrorRecord.Exception
	for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) 
	{
		"$i" * 70
		$Exception | Format-List * -Force
	}
}

function Write-Documentation 
{
	$list = New-Object System.Collections.ArrayList
	foreach($key in $global:tasks.Keys) 
	{
		if($key -eq "default") 
		{
		  continue
		}
		$task = $global:tasks.$key
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
	while ($global:executedTasks.Count -gt 0) 
	{
		$name = $global:executedTasks.Pop()
		$task = $global:tasks.$name
		if($name -eq "default") 
		{
		  continue
		}    
		$list += "" | Select-Object @{Name="Name";Expression={$name}}, @{Name="Duration";Expression={$task.Duration}}
	}
	[Array]::Reverse($list)
	$list += "" | Select-Object @{Name="Name";Expression={"Total:"}}, @{Name="Duration";Expression={$stopwatch.Elapsed}}
	$list | Format-Table -Auto | Out-String -Stream | ? {$_}  # using "Out-String -Stream" to filter out the blank line that Format-Table prepends 
}

function Run-psake 
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
.Parameter ShowFullError
	Displays detailed error information when an error occurs
.Parameter Timing 
	Prints a report showing how long each task took to execute
.Parameter Docs 
	Prints a list of tasks and their descriptions
.Parameter NoExit
	Does not use 'exit' command when an error occurs or when printing documentation - useful when running a build interactively
	
.Example
    Run-psake 
	
	Runs the 'default' task in the 'default.ps1' build script in the current directory
.Example
	Run-psake '.\build.ps1'
	
	Runs the 'default' task in the '.build.ps1' build script
.Example
	Run-psake '.\build.ps1' Tests, Package
	
	Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script
.Example
	Run-psake '.\build.ps1' -timing
	
	Runs the 'default' task in the '.build.ps1' build script and prints a timing report
.Example
	Run-psake '.\build.ps1' -debuginfo
	
	Runs the 'default' task in the '.build.ps1' build script and prints a report of what includes, properties and tasks are in the build script
.Example
	Run-psake '.\build.ps1' -docs
	
	Prints a report of all the tasks and their descriptions and exits
	
.ReturnValue
    Calls exit() function with 0 for success and 1 for failure 
	If $noexit is $true then exit() is not called and no value is returned  
.Link	
.Notes
 NAME:      Run-psake
 AUTHOR:    Jorge Matos
 LASTEDIT:  05/04/2009
#Requires -Version 2.0
#>
[CmdletBinding(
    SupportsShouldProcess=$False,
    SupportsTransactions=$False, 
    ConfirmImpact="None",
    DefaultParameterSetName="")]
	
	param(
	  [string]$buildFile = 'default.ps1',
	  [string[]]$taskList = @(),
	  [string]$framework = '3.5',
	  [switch]$showFullError = $false,	 
	  [switch]$timing = $false,
	  [switch]$docs = $false,
	  [switch]$noexit = $false
	)

	Begin 
	{
		$global:tasks = @{}
		$global:properties = @()
		$global:includes = New-Object System.Collections.Queue
		$global:psake_version = "0.23"
		$global:psake_buildScript = $buildFile
		$global:psake_frameworkVersion = $framework
		$global:psake_buildSucceeded = $true
		$global:formatTaskNameString = $null
		$global:taskSetupScriptBlock = $null
		$global:taskTearDownScriptBlock = $null

		$global:executedTasks = New-Object System.Collections.Stack
		$global:callStack = New-Object System.Collections.Stack
		$global:originalEnvPath = $env:path
		$global:originalDirectory = Get-Location
		$originalErrorActionPreference = $Global:ErrorActionPreference
	}
	
	Process 
	{	
		try 
		{
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

			# Execute the build file to set up the tasks and defaults
			if(test-path $buildFile) 
			{
				$buildFile = resolve-path $buildFile
				set-location (split-path $buildFile)
				& $buildFile
			} 
			else 
			{
				throw "Error: Could not find the build file, $buildFile."
			}

			Configure-BuildEnvironment

			# N.B. The initial dot (.) indicates that variables initialized/modified
			#      in the propertyBlock are available in the parent scope.
			while ($global:includes.Count -gt 0) 
			{
				$includeBlock = $global:includes.Dequeue()
				. $includeBlock;
			}
			foreach($propertyBlock in $global:properties) 
			{
				. $propertyBlock
			}

			if($docs) 
			{
				Write-Documentation
				Cleanup-Environment
				if ($noexit) 
				{ 					
					return
				} 
				else 
				{
					exit(0)
				}				
			}

			# Execute the list of tasks or the default task
			if($taskList.Length -ne 0) 
			{
				foreach($task in $taskList) 
				{
					ExecuteTask $task
				}
			} 
			elseif ($global:tasks.default -ne $null) 
			{
				ExecuteTask default
			} 
			else 
			{
				throw 'Error: default task required'
			}

			$stopwatch.Stop()

			if ($timing) 
			{	
				Write-TaskTimeSummary
			}
			
			$global:psake_buildSucceeded = $true
		} 
		catch 
		{			
			if ($showFullError)
			{
				"-" * 70 
				"{0}: An Error Occurred. See Error Details Below: " -f [DateTime]::Now
				"-" * 70 
				Resolve-Error $_
				"-" * 70
			}
			else
			{
				$file = split-path $global:psake_buildScript -leaf
				Write-Host -foregroundcolor Red ($file + ":" + $_)
			}
			
			Cleanup-Environment		
			
			if ($noexit) 
			{ 
				$global:psake_buildSucceeded = $false				 
			} 
			else 
			{
				exit(1)
			}
		}
	} #Process
	
	End 
	{
		# Clear out any global variables
		Cleanup-Environment
	}
}

Export-ModuleMember "Run-psake","Task","Properties","Include","FormatTaskName","TaskSetup","TaskTearDown"