# psake v0.11
# Copyright © 2008 James Kovacs
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

param(
  [string]$buildFile = 'default.ps1',
  [string[]]$taskList = @(),
  [string]$framework = '3.5',
  [switch]$debug = $false,
  [switch]$help  = $false
)

if($help) {
@"
psake [buildFile] [tasks] [-framework ver] [-debug]
  where buildFile is the name of the build file, (default: default.ps1)
        tasks is a list of tasks to execute from the build file,
        ver is the .NET Framework version to target - 1.0, 1.1, 2.0, 3.0, or 3.5
            3.5 is the default
        debug dumps information the tasks.
psake -help
  Displays this message.
"@
  return
}

$global:tasks = @{}
$global:properties = @()
$script:executedTasks = New-Object System.Collections.Stack
$script:callStack = New-Object System.Collections.Stack
$originalEnvPath = $env:path
$originalDirectory = Get-Location

function task([string]$name, [scriptblock]$action = $null, [string[]]$depends = @()) {
  if($name -eq 'default' -and $action -ne $null) {
    throw "Error: default task cannot specify an action"
  }
  $newTask = @{
    Name = $name
    DependsOn = $depends
    Action = $action
  }
  if($global:tasks.$name -ne $null) { throw "Error: Task, $name, has already been defined." }
  $global:tasks.$name = $newTask
}

function properties([scriptblock]$propertyBlock) {
  $global:properties += $propertyBlock
}

function AssertNotCircular([string]$name) {
  if($script:callStack.Contains($name)) {
    throw "Circular reference found for task, $name"
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
    Write-Host "Executing task, $name..."
    if($task.Action -ne $null) {
      & $task.Action
    }
    Write-Host "`n"
  }
  
  $poppedTask = $script:callStack.Pop()
  if($poppedTask -ne $name) {
    throw "CallStack was corrupt. Expected $name, but got $poppedTask."
  }
  $script:executedTasks.Push($name)
}

function DumpTasks {
  Write-Host 'Dumping tasks:'
  foreach($key in $global:tasks.Keys) {
    $task = $global:tasks.$key;
    $task.Name + " depends on " + $task.DependsOn.Length + " other tasks: " + $task.DependsOn;
  }
  Write-Host "`n"
}

function DumpProperties {
  Write-Host 'Dumping properties:'
  $global:properties
}

function ConfigureEnvForBuild {
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
}

function Cleanup {
  $env:path = $originalEnvPath
  $global:tasks = $null
  Set-Location $originalDirectory
}

function RunBuild {
  # Faking a finally block
  trap {
    Write-Host -foregroundcolor Red $_
    Cleanup
    break
  }

  # Execute the build file to set up the tasks and defaults
  if(test-path $buildFile) {
    $buildFile = resolve-path $buildFile
    set-location (split-path $buildFile)
    & $buildFile
  } else {
    throw "Error: Could not find the build file, $buildFile."
  }

  if($debug) {
    DumpProperties
    DumpTasks
  }

  ConfigureEnvForBuild
  
  foreach($propertyBlock in $global:properties) {
    # N.B. The initial dot (.) indicates that variables initialized/modified
    #      in the propertyBlock are available in the parent scope.
    . $propertyBlock
  }

  # Execute the list of tasks or the default task
  if($taskList.Length -ne 0) {
    foreach($task in $taskList) {
      ExecuteTask $task
    }
  } elseif ($global:tasks.default -ne $null) {
    EXecuteTask default
  }

  # Clear out any global variables
  Cleanup
}

# Avoids printing of error dump with line numbers
trap {
 # continue
}

RunBuild