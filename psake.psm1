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

#Ensure that only one instance of the psake module is loaded 
remove-module psake -erroraction silentlycontinue

#-- Public Module Functions --#

# .ExternalHelp  psake.psm1-help.xml
function Invoke-Task
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)] [string]$taskName
    )

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

    if (!$precondition_is_valid) {
        Write-ColoredOutput ($msgs.precondition_was_false -f $taskName) -foregroundcolor Blue
    } else {
        if ($taskKey -ne 'default') {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            if ($task.PreAction -or $task.PostAction) {
                Assert ($task.Action -ne $null) $msgs.error_missing_action_parameter
            }

            if ($task.Action) {
                try {
                    foreach($childTask in $task.DependsOn) {
                        Invoke-Task $childTask
                    }

                    $currentContext.currentTaskName = $taskName

                    & $currentContext.taskSetupScriptBlock

                    if ($task.PreAction) {
                        & $task.PreAction
                    }

                    if ($currentContext.config.taskNameFormat -is [ScriptBlock]) {
                        & $currentContext.config.taskNameFormat $taskName
                    } else {
                        Write-ColoredOutput ($currentContext.config.taskNameFormat -f $taskName) -foregroundcolor Blue
                    }

                    & $task.Action 

                    if ($task.PostAction) {
                        & $task.PostAction
                    }

                    & $currentContext.taskTearDownScriptBlock
                } catch {
                    if ($task.ContinueOnError) {
                        "-"*70            
                        $msgs.continue_on_error -f $taskName,$_
                        "-"*70
                    }  else {
                        throw $_
                    }
                }
            } else { 
                #no Action was specified but we still execute all the dependencies
                foreach($childTask in $task.DependsOn) {
                    Invoke-Task $childTask
                }
            }
            $stopwatch.stop()
            $task.Duration = $stopwatch.Elapsed
        } else {
            foreach($childTask in $task.DependsOn) {
                Invoke-Task $childTask
            }
        }

        Assert (& $task.Postcondition) ($msgs.postcondition_failed -f $taskName)
    }

    $poppedTaskKey = $callStack.Pop()
    Assert ($poppedTaskKey -eq $taskKey) ($msgs.error_corrupt_callstack -f $taskKey,$poppedTaskKey)

    $executedTasks.Push($taskKey)
}

# .ExternalHelp  psake.psm1-help.xml
function Exec
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$cmd,
        [Parameter(Position=1,Mandatory=0)][string]$errorMessage = ($msgs.error_bad_command -f $cmd)
    )
    & $cmd
    if ($lastexitcode -ne 0) {
        throw ("Exec: " + $errorMessage)
    }
}

# .ExternalHelp  psake.psm1-help.xml
function Assert
{
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)]$conditionToCheck,
        [Parameter(Position=1,Mandatory=1)]$failureMessage
    )
    if (!$conditionToCheck) { 
        throw ("Assert: " + $failureMessage) 
    }
}

# .ExternalHelp  psake.psm1-help.xml
function Task
{
    [CmdletBinding()]  
    param(
        [Parameter(Position=0,Mandatory=1)] [string]$name = $null,
        [Parameter(Position=1,Mandatory=0)] [scriptblock]$action = $null,    
        [Parameter(Position=2,Mandatory=0)] [scriptblock]$preaction = $null,    
        [Parameter(Position=3,Mandatory=0)] [scriptblock]$postaction = $null,    
        [Parameter(Position=4,Mandatory=0)] [scriptblock]$precondition = {$true},    
        [Parameter(Position=5,Mandatory=0)] [scriptblock]$postcondition = {$true},    
        [Parameter(Position=6,Mandatory=0)] [switch]$continueOnError = $false,    
        [Parameter(Position=7,Mandatory=0)] [string[]]$depends = @(),    
        [Parameter(Position=8,Mandatory=0)] [string]$description = $null
    )

    if ($name -eq 'default') {
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

# .ExternalHelp  psake.psm1-help.xml
function Properties {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$properties
    )
    $psake.context.Peek().properties += $properties
}

# .ExternalHelp  psake.psm1-help.xml
function Include {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string]$fileNamePathToInclude
    )
    Assert (test-path $fileNamePathToInclude) ($msgs.error_invalid_include_path -f $fileNamePathToInclude)
    $psake.context.Peek().includes.Enqueue((Resolve-Path $fileNamePathToInclude));
}

# .ExternalHelp  psake.psm1-help.xml
function FormatTaskName {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)]$format
    )
    $psake.context.Peek().config.taskNameFormat = $format
}

# .ExternalHelp  psake.psm1-help.xml
function TaskSetup {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$setup
    )
    $psake.context.Peek().taskSetupScriptBlock = $setup
}

# .ExternalHelp  psake.psm1-help.xml
function TaskTearDown {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][scriptblock]$teardown
    )
    $psake.context.Peek().taskTearDownScriptBlock = $teardown
}

# .ExternalHelp  psake.psm1-help.xml
function Framework {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=1)][string]$framework
    )
    $psake.context.Peek().config.framework = $framework
}

# .ExternalHelp  psake.psm1-help.xml
function Invoke-psake {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = 0)][string] $buildFile, 
        [Parameter(Position = 1, Mandatory = 0)][string[]] $taskList = @(), 
        [Parameter(Position = 2, Mandatory = 0)][string] $framework,
        [Parameter(Position = 3, Mandatory = 0)][switch] $docs = $false, 
        [Parameter(Position = 4, Mandatory = 0)][hashtable] $parameters = @{}, 
        [Parameter(Position = 5, Mandatory = 0)][hashtable] $properties = @{},
        [Parameter(Position = 6, Mandatory = 0)][switch] $nologo = $false
    )
    try {
        if (-not $nologo) {
            "psake version {0}`nCopyright (c) 2010 James Kovacs`n" -f $psake.version
        }
 
        # If the default.ps1 file exists and the given "buildfile" isn 't found assume that the given 
        # $buildFile is actually the target Tasks to execute in the default.ps1 script. 
        if ($buildFile -and !(test-path $buildFile) -and (test-path $psake.config_default.buildFileName)) {
            $taskList = $buildFile.Split(', ')
            $buildFile = $psake.config_default.buildFileName
        }

        # Execute the build file to set up the tasks and defaults
        Assert (test-path $buildFile) ($msgs.error_build_file_not_found -f $buildFile)

        $psake.build_script_file = get-item $buildFile
        $psake.build_script_dir = $psake.build_script_file.DirectoryName
        $psake.build_success = $false

        $psake.context.push(@{
            "taskSetupScriptBlock" = {};
            "taskTearDownScriptBlock" = {};
            "executedTasks" = new-object System.Collections.Stack;
            "callStack" = new-object System.Collections.Stack;
            "originalEnvPath" = $env:path;
            "originalDirectory" = get-location;
            "originalErrorActionPreference" = $global:ErrorActionPreference;
            "tasks" = @{};
            "properties" = @();
            "includes" = new-object System.Collections.Queue;
            "config" = Create-ConfigurationForNewContext $buildFile $framework
        })

        Load-Configuration $psake.build_script_dir

        Load-Modules
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        set-location $psake.build_script_dir
        
        $frameworkOldValue = $framework
        . $psake.build_script_file.FullName

        $currentContext = $psake.context.Peek()

        if ($framework -ne $frameworkOldValue) {
            write-coloredoutput $msgs.warning_deprecated_framework_variable -foregroundcolor Yellow
            $currentContext.config.framework = $framework
        }

        if ($docs) {
            Write-Documentation
            Cleanup-Environment
            return
        }

        Configure-BuildEnvironment

        while ($currentContext.includes.Count -gt 0) {
            $includeFilename = $currentContext.includes.Dequeue()
            . $includeFilename
        }

        foreach ($key in $parameters.keys) {
            if (test-path "variable:\$key") {
                set-item -path "variable:\$key" -value $parameters.$key | out-null
            } else {
                new-item -path "variable:\$key" -value $parameters.$key | out-null
            }
        }

        # N.B. The initial dot (.) indicates that variables initialized/modified
        #      in the propertyBlock are available in the parent scope.
        foreach ($propertyBlock in $currentContext.properties) {
            . $propertyBlock 
        }

        foreach ($key in $properties.keys) {
            if (test-path "variable:\$key") {
                set-item -path "variable:\$key" -value $properties.$key | out-null
            }
        }

        # Execute the list of tasks or the default task
        if ($taskList) {
            foreach ($task in $taskList) {
                invoke-task $task
            }
        } elseif ($currentContext.tasks.default) {
            invoke-task default
        } else {
            throw $msgs.error_no_default_task
        }

        $stopwatch.Stop()

        Write-ColoredOutput ("`n" + $msgs.build_success + "`n") -foregroundcolor Green

        Write-TaskTimeSummary

        $psake.build_success = $true
    } catch {
        $currentConfig = Get-CurrentConfigurationOrDefault
        if ($currentConfig.verboseError) {
            $error_message = "{0}: An Error Occurred. See Error Details Below: `n" -f (Get-Date) 
            $error_message += ("-" * 70) + "`n"
            $error_message += Resolve-Error $_
            $error_message += ("-" * 70) + "`n"
            $error_message += "Script Variables" + "`n"
            $error_message += ("-" * 70) + "`n"
            $error_message += get-variable -scope script | format-table | out-string 
        } else {
            $error_message = "{0}: An Error Occurred: `n{1}" -f (Get-Date), $_
        }

        $psake.build_success = $false

        if (!$psake.run_by_psake_build_tester) {
            #if we are running in a nested scope (i.e. running a psake script from a psake script) then we need to re-throw the exception
            #so that the parent script will fail otherwise the parent script will report a successful build 
            $inNestedScope = ($psake.context.count -gt 1)
            if ( $inNestedScope ) {
                throw $_
            } else {
                Write-ColoredOutput $error_message -foregroundcolor Red
            }

        }
    } finally {
        Cleanup-Environment
    }
} #Invoke-psake

#-- Private Module Functions --#
function Write-ColoredOutput {
    param(
        [string] $message,
        [System.ConsoleColor] $foregroundcolor
    )

    $currentConfig = Get-CurrentConfigurationOrDefault
    if ($currentConfig.coloredOutput -eq $true) {
        if (($Host.UI -ne $null) -and ($Host.UI.RawUI -ne $null)) {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $foregroundcolor
        }
    }

    $message

    if ($previousColor -ne $null) {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}

function Load-Modules {
    $modules = $null

    $currentConfig = $psake.context.peek().config
    if ($currentConfig.modules.autoload) {
        if ($currentConfig.modules.directory) {
            Assert (test-path $currentConfig.modules.directory) ($msgs.error_invalid_module_dir -f $currentConfig.modules.directory)
            $modules = get-item(join-path $currentConfig.modules.directory "*.psm1")
        }
        elseif (test-path (join-path $PSScriptRoot "modules")) {
            $modules = get-item (join-path (join-path $PSScriptRoot "modules") "*.psm1")
        }
    } else {
        if ($currentConfig.modules.module) {
            $modules = $currentConfig.modules.module | % {
                Assert (test-path $_.path) ($msgs.error_invalid_module_path -f $_.path);
                get-item $_.path
            }
        }
    }

    if ($modules) {
        $modules | % {
            "loading module: $_";
            $module = import-module $_ -passthru;
            if (!$module) {
                throw ($msgs.error_loading_module -f $_.Name)
            }
        }
        ""
    }
}

function Load-Configuration {
    param(
        [string] $configdir = $PSScriptRoot
    )

    $psakeConfigFilePath = (join-path $configdir "psake-config.ps1")

    if (test-path $psakeConfigFilePath) {
        try {
            $config = Get-CurrentConfigurationOrDefault
            . $psakeConfigFilePath
        } catch {
            throw "Error Loading Configuration from psake-config.ps1: " + $_
        }
    }
}

function Get-CurrentConfigurationOrDefault() {
    if ($psake.context.count -gt 0) {
        return $psake.context.peek().config
    } else {
        return $psake.config_default
    }
}

function Create-ConfigurationForNewContext {
    param(
        [string] $buildFile,
        [string] $framework
    )

    $previousConfig = Get-CurrentConfigurationOrDefault

    $config = new-object psobject -property @{
        buildFileName = $previousConfig.buildFileName;
        framework = $previousConfig.framework;
        taskNameFormat = $previousConfig.taskNameFormat;
        verboseError = $previousConfig.verboseError;
        coloredOutput = $previousConfig.coloredOutput;
        modules = $previousConfig.modules
    }

    if ($framework) {
        $config.framework = $framework;
    }

    if ($buildFile) {
        $config.buildFileName = $buildFile;
    }

    return $config
}

function Configure-BuildEnvironment {
    $framework = $psake.context.peek().config.framework
    if ($framework.Length -ne 3 -and $framework.Length -ne 6) {
        throw ($msgs.error_invalid_framework -f $framework)
    }
    $versionPart = $framework.Substring(0, 3)
    $bitnessPart = $framework.Substring(3)
    $versions = $null
    switch ($versionPart) {
        '1.0' {
            $versions = @('v1.0.3705')
        }
        '1.1' {
            $versions = @('v1.1.4322')
        }
        '2.0' {
            $versions = @('v2.0.50727')
        }
        '3.0' {
            $versions = @('v2.0.50727')
        }
        '3.5' {
            $versions = @('v3.5', 'v2.0.50727')
        }
        '4.0' {
            $versions = @('v4.0.30319')
        }
        default {
            throw ($msgs.error_unknown_framework -f $versionPart, $framework)
        }
    }

    $bitness = 'Framework'
    if ($versionPart -ne '1.0' -and $versionPart -ne '1.1') {
        switch ($bitnessPart) {
            'x86' {
                $bitness = 'Framework'
            }
            'x64' {
                $bitness = 'Framework64'
            }
            $null {
                $ptrSize = [System.IntPtr]::Size
                switch ($ptrSize) {
                    4 {
                        $bitness = 'Framework'
                    }
                    8 {
                        $bitness = 'Framework64'
                    }
                    default {
                        throw ($msgs.error_unknown_pointersize -f $ptrSize)
                    }
                }
            }
            default {
                throw ($msgs.error_unknown_bitnesspart -f $bitnessPart, $framework)
            }
        }
    }
    $frameworkDirs = $versions | foreach { "$env:windir\Microsoft.NET\$bitness\$_\" }

    $frameworkDirs | foreach { Assert (test-path $_) ($msgs.error_no_framework_install_dir_found -f $_)}

    $env:path = ($frameworkDirs -join ";") + ";$env:path"
    #if any error occurs in a PS function then "stop" processing immediately
    #this does not effect any external programs that return a non-zero exit code
    $global:ErrorActionPreference = "Stop"
}

function Cleanup-Environment {
    if ($psake.context.Count -gt 0) {
        $currentContext = $psake.context.Peek()
        $env:path = $currentContext.originalEnvPath
        Set-Location $currentContext.originalDirectory
        $global:ErrorActionPreference = $currentContext.originalErrorActionPreference
        [void] $psake.context.Pop()
    }
}

#borrowed from Jeffrey Snover http://blogs.msdn.com/powershell/archive/2006/12/07/resolve-error.aspx
function Resolve-Error($ErrorRecord = $Error[0]) {
    $error_message = "`nErrorRecord:{0}ErrorRecord.InvocationInfo:{1}Exception:{2}"
    $formatted_errorRecord = $ErrorRecord | format-list * -force | out-string
    $formatted_invocationInfo = $ErrorRecord.InvocationInfo | format-list * -force | out-string
    $formatted_exception = ""
    $Exception = $ErrorRecord.Exception
    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException)) {
        $formatted_exception += ("$i" * 70) + "`n"
        $formatted_exception += $Exception | format-list * -force | out-string
        $formatted_exception += "`n"
    }

    return $error_message -f $formatted_errorRecord, $formatted_invocationInfo, $formatted_exception
}

function Write-Documentation {
    $currentContext = $psake.context.Peek()

    if ($currentContext.tasks.default) {
        $defaultTaskDependencies = $currentContext.tasks.default.DependsOn
    } else {
        $defaultTaskDependencies = @()
    }

    $currentContext.tasks.Keys | foreach-object {
        if ($_ -eq "default") {
            return
        }

        $task = $currentContext.tasks.$_
        new-object PSObject -property @{
            Name = $task.Name;
            Description = $task.Description;
            "Depends On" = $task.DependsOn -join ", "
            Default = if ($defaultTaskDependencies -contains $task.Name) { $true }
        }
    } | sort 'Name' | format-table -Auto -Property Name,Description,"Depends On",Default
}

function Write-TaskTimeSummary {
    "-" * 70 
    "Build Time Report"
    "-" * 70
    $list = @()
    $currentContext = $psake.context.Peek()
    while ($currentContext.executedTasks.Count -gt 0) {
        $taskKey = $currentContext.executedTasks.Pop()
        $task = $currentContext.tasks.$taskKey
        if ($taskKey -eq "default") {
            continue
        }
        $list += new-object PSObject -property @{
            Name = $task.Name;
            Duration = $task.Duration
        }
    }
    [Array]::Reverse($list)
    $list += new-object PSObject -property @{
        Name = "Total:";
        Duration = $stopwatch.Elapsed
    }
    $list | format-table -auto -Property Name,Duration | out-string -stream | ? { $_ } #using "Out-String -Stream" to filter out the blank line that Format-Table prepends
}

DATA msgs {
convertfrom-stringdata @'
    error_invalid_task_name = Task name should not be null or empty string
    error_task_name_does_not_exist = task [{0}] does not exist
    error_circular_reference = Circular reference found for task, {0}
    error_missing_action_parameter = Action parameter must be specified when using PreAction or PostAction parameters
    error_corrupt_callstack = CallStack was corrupt. Expected {0}, but got {1}.
    error_invalid_framework = Invalid .NET Framework version, {0}, specified
    error_unknown_framework = Unknown .NET Framework version, {0}, specified in {1}
    error_unknown_pointersize = Unknown pointer size ({0}) returned from System.IntPtr.
    error_unknown_bitnesspart = Unknown .NET Framework bitness, {0}, specified in {1}
    error_no_framework_install_dir_found = No .NET Framework installation directory found at {0}
    error_bad_command = Error executing command: {0}
    error_default_task_cannot_have_action = 'default' task cannot specify an action
    error_duplicate_task_name = Task {0} has already been defined.
    error_invalid_include_path = Unable to include {0}. File not found.
    error_build_file_not_found = Could not find the build file, {0}.
    error_no_default_task = default task required
    error_invalid_module_dir = Unable to load modules from directory: {0}
    error_invalid_module_path = Unable to load module at path: {0}
    error_loading_module = Error loading module: {0}
    warning_deprecated_framework_variable = Warning: Using global variable $framework to set .NET framework version used is deprecated. Instead use Framework function or configuration file psake-config.ps1
    postcondition_failed = Postcondition failed for {0}
    precondition_was_false = Precondition was false not executing {0}
    continue_on_error = Error in Task [{0}] {1}
    build_success = Build Succeeded!
'@
} 

import-localizeddata -bindingvariable msgs -erroraction silentlycontinue

$script:psake = @{}
$psake.version = "4.00" # contains the current version of psake
$psake.context = new-object system.collections.stack # holds onto the current state of all variables
$psake.run_by_psake_build_tester = $false # indicates that build is being run by psake-BuildTester
$psake.config_default = new-object psobject -property @{
    buildFileName = "default.ps1";
    framework = "3.5";
    taskNameFormat = "Executing {0}";
    verboseError = $false;
    coloredOutput = $true;
    modules = (new-object PSObject -property @{
        autoload = $false
    })
} # contains default configuration, can be overriden in psake-config.ps1 in directory with psake.psm1 or in directory with current build script

$psake.build_success = $false # indicates that the current build was successful
$psake.build_script_file = $null # contains a System.IO.FileInfo for the current build script
$psake.build_script_dir = "" # contains a string with fully-qualified path to current build script

Load-Configuration

export-modulemember -function invoke-psake, invoke-task, task, properties, include, formattaskname, tasksetup, taskteardown, framework, assert, exec -variable psake
