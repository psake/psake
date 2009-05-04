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

function task([string]$name=$null, [scriptblock]$action = $null, [scriptblock]$precondition = $null, [scriptblock]$postcondition = $null, [switch]$continueOnError = $false, [string[]]$depends = @(), [string]$description = $null) {
  if (($name -eq $null) -or ($name.Trim() -eq "")) {
	  throw "Error: Task must have a name"	
  }
  if($name.ToLower() -eq 'default' -and $action -ne $null) {
    throw "Error: Default task cannot specify an action"
  }
  $newTask = @{
    Name = $name
    DependsOn = $depends
    Action = $action
    Precondition = $precondition
    Postcondition = $postcondition
    ContinueOnError = $continueOnError
    Description = $description
  }
  if($global:tasks.$name -ne $null) { throw "Error: Task, $name, has already been defined." }
  $global:tasks.$name = $newTask
}

function properties([scriptblock]$propertyBlock) {
  $global:properties += $propertyBlock
}

function include([string]$include){
  if (!(test-path $include)) { throw "Error: $include not found."} 	
  $global:includes.Enqueue((Resolve-Path $include));
}

function AssertNotCircular([string]$name) {
  if($script:callStack.Contains($name)) {
    throw "Error: Circular reference found for task, $name"
  }
}

function ExecuteTask([string]$name) {
  if($script:executedTasks.Contains($name)) { return }
  AssertNotCircular $name
  $script:callStack.Push($name)
  
  $task = $global:tasks.$name
  foreach($childTask in $task.DependsOn) {
    ExecuteTask $childTask
  }
  if($name -ne 'default') {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $precondition = $true
    if($task.Precondition -ne $null) {
      $precondition = (& $task.Precondition)
    }
    "Executing task, $name..."
    if($task.Action -ne $null) {
      if($precondition) {
        trap {
          if ($task.ContinueOnError) {
			"-"*70
            "Error in Task [$name] $_"
			"-"*70
            continue
          } else {
            throw $_
          }
        }                
        & $task.Action
        $postcondition = $true
        if($task.Postcondition -ne $null) {
          $postcondition = (& $task.Postcondition)
        }
        if (!$postcondition) {
          throw "Error: Postcondition failed for $name"
        }
      } else {
        "Precondition was false not executing $name"
      }
    }    
    $stopwatch.stop()
    $task.Duration = $stopwatch.Elapsed
  }

  $poppedTask = $script:callStack.Pop()
  if($poppedTask -ne $name) {
    throw "Error: CallStack was corrupt. Expected $name, but got $poppedTask."
  }
  $script:executedTasks.Push($name)
}

function Dump-Tasks {
  'Dumping tasks:'
  foreach($key in $global:tasks.Keys) {
    $task = $global:tasks.$key;
    $task.Name + " depends on " + $task.DependsOn.Length + " other tasks: " + $task.DependsOn;
  }
  "`n"
}

function Dump-Properties {
  'Dumping properties:'
  $global:properties
}

function Dump-Includes {
  'Dumping includes:'
  $global:includes
}

function Configure-BuildEnvironment {
  $version = $null
  switch ($framework) {
    '1.0' { $version = 'v1.0.3705'  }
    '1.1' { $version = 'v1.1.4322'  }
    '2.0' { $version = 'v2.0.50727' }
    '3.0' { $version = 'v2.0.50727' } # .NET 3.0 uses the .NET 2.0 compilers
    '3.5' { $version = 'v3.5'       }
    default { throw "Error: Unknown .NET Framework version, $framework" }
  }
  $frameworkDir = "$env:windir\Microsoft.NET\Framework\$version\"
  if(!(test-path $frameworkDir)) {
    throw "Error: No .NET Framework installation directory found at $frameworkDir"
  }
  $env:path = "$frameworkDir;$env:path"
  $global:ErrorActionPreference = "Stop"
}

function Cleanup-Environment {
  $env:path = $script:originalEnvPath	
  Set-Location $script:originalDirectory
  $global:ErrorActionPreference = $originalErrorActionPreference
  remove-variable tasks -scope "global" -ErrorAction SilentlyContinue
  remove-variable properties -scope "global" -ErrorAction SilentlyContinue
  remove-variable includes -scope "global" -ErrorAction SilentlyContinue
  remove-variable psake_version -scope "global" -ErrorAction SilentlyContinue 
  remove-variable psake_buildScript -scope "global" -ErrorAction SilentlyContinue 
  remove-variable psake_frameworkVersion -scope "global" -ErrorAction SilentlyContinue 
  if (!$noexit) {
	remove-variable psake_buildSucceeded -scope "global" -ErrorAction SilentlyContinue 
  }  
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord=$Error[0]) {	
  $ErrorRecord | Format-List * -Force
  $ErrorRecord.InvocationInfo | Format-List *
  $Exception = $ErrorRecord.Exception
  for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
    "$i" * 70
    $Exception | Format-List * -Force
  }
}

function Write-Documentation {
  $list = New-Object System.Collections.ArrayList
  foreach($key in $global:tasks.Keys) {
    if($key -eq "default") {
      continue;
    }
    $task = $global:tasks.$key;
    $content = "" | Select-Object Name, Description
    $content.Name = $task.Name        
    $content.Description = $task.Description
    $index = $list.Add($content);
  }
  
  $list | Sort 'Name' | Format-Table -Auto
}

function exec([string]$command, [string]$parameters) {    
    & $command $parameters
    if ($lastExitCode -ne 0) {
        throw "Error: Failed to execute ""$command"" with parameters ""$parameters"""
    }
}

function PrintBuildTimingReport() {
	"-"*70
	"Build Time Report"
	"-"*70	
	$list = @()
	while ($script:executedTasks.Count -gt 0) {
		$name = $script:executedTasks.Pop()
		$task = $global:tasks.$name
		if($name -eq "default") {
		  continue;
		}    
		$list += "" | Select-Object @{Name="Name";Expression={$name}}, @{Name="Duration";Expression={$task.Duration}}
	}
	[Array]::Reverse($list)
	$list += "" | Select-Object @{Name="Name";Expression={"Total:"}}, @{Name="Duration";Expression={$stopwatch.Elapsed}}
	$list | Format-Table -Auto | Out-String -Stream | ? {$_}  # using "Out-String -Stream" to filter out the blank line that Format-Table prepends 
}

function Run-psake {
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
.Parameter debuginfo 
	Dumps information on the properties, includes, and tasks, as well as more detailed error information.
.Parameter timing 
	Prints a report showing how long each task took to execute
.Parameter docs 
	Prints a list of tasks and their descriptions
.Parameter noexit
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
	  [switch]$debuginfo = $false,	 
	  [switch]$timing = $false,
	  [switch]$docs = $false,
	  [switch]$noexit = $false
	)

	Begin {
		$global:tasks = @{}
		$global:properties = @()
		$global:includes = New-Object System.Collections.Queue
		$global:psake_version = "0.23"
		$global:psake_buildScript = $buildFile
		$global:psake_frameworkVersion = $framework
		$global:psake_buildSucceeded = $true

		$script:executedTasks = New-Object System.Collections.Stack
		$script:callStack = New-Object System.Collections.Stack
		$script:originalEnvPath = $env:path
		$script:originalDirectory = Get-Location
		$originalErrorActionPreference = $Global:ErrorActionPreference
	}
	
	Process {	
		try {
			$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

			# Execute the build file to set up the tasks and defaults
			if(test-path $buildFile) {
				$buildFile = resolve-path $buildFile
				set-location (split-path $buildFile)
				& $buildFile
			} else {
				throw "Error: Could not find the build file, $buildFile."
			}

			if($debuginfo) {
				Dump-Includes
				Dump-Properties
				Dump-Tasks
			}

			Configure-BuildEnvironment

			# N.B. The initial dot (.) indicates that variables initialized/modified
			#      in the propertyBlock are available in the parent scope.
			while ($global:includes.Count -gt 0) {
			$includeBlock = $global:includes.Dequeue()
				. $includeBlock;
			}
			foreach($propertyBlock in $global:properties) {
				. $propertyBlock
			}

			if($docs) {
				Write-Documentation
				Cleanup-Environment
				if ($noexit) { 					
					return
				} else {
					exit(0)
				}				
			}

			# Execute the list of tasks or the default task
			if($taskList.Length -ne 0) {
				foreach($task in $taskList) {
				  ExecuteTask $task
				}
			} elseif ($global:tasks.default -ne $null) {
				ExecuteTask default
			} else {
				throw 'Error: default task required'
			}

			$stopwatch.Stop()

			if ($timing) {	
				PrintBuildTimingReport
			}
			
			$global:psake_buildSucceeded = $true
		} catch {
			Cleanup-Environment
			Write-Host -foregroundcolor Red $_
			if($debuginfo) {
			  "-" * 80
			  "An Error Occurred. See Error Details Below:"
			  "-" * 80
			  Resolve-Error
			  "-" * 80
			}
			if ($noexit) { 
				$global:psake_buildSucceeded = $false				 
			} else {
				exit(1)
			}
		}
	} #Process
	
	End {
		# Clear out any global variables
		Cleanup-Environment
	}
}

Export-ModuleMember "Run-psake", "task", "properties", "include"