function Task {
    <#
        .SYNOPSIS
        Defines a build task to be executed by psake

        .DESCRIPTION
        This function creates a 'task' object that will be used by the psake engine to execute a build task.
        Note: There must be at least one task called 'default' in the build script

        .PARAMETER Name
        The name of the task

        .PARAMETER Action
        A scriptblock containing the statements to execute for the task.

        .PARAMETER PreAction
        A scriptblock to be executed before the 'Action' scriptblock.
        Note: This parameter is ignored if the 'Action' scriptblock is not defined.

        .PARAMETER PostAction
        A scriptblock to be executed after the 'Action' scriptblock.
        Note: This parameter is ignored if the 'Action' scriptblock is not defined.

        .PARAMETER PreCondition
        A scriptblock that is executed to determine if the task is executed or skipped.
        This scriptblock should return $true or $false

        .PARAMETER PostCondition
        A scriptblock that is executed to determine if the task completed its job correctly.
        An exception is thrown if the scriptblock returns $false.

        .PARAMETER ContinueOnError
        If this switch parameter is set then the task will not cause the build to fail when an exception is thrown by the task

        .PARAMETER Depends
        An array of task names that this task depends on.
        These tasks will be executed before the current task is executed.

        .PARAMETER RequiredVariables
        An array of names of variables that must be set to run this task.

        .PARAMETER Description
        A description of the task.

        .PARAMETER Alias
        An alternate name for the task.

        .PARAMETER FromModule
        Load in the task from the specified PowerShell module.

        .PARAMETER RequiredVersion
        The specific version of a module to load the task from

        .PARAMETER MinimumVersion
        The minimum (inclusive) version of the PowerShell module to load in the task from.

        .PARAMETER MaximumVersion
        The maximum (inclusive) version of the PowerShell module to load in the task from.

        .PARAMETER LessThanVersion
        The version of the PowerShell module to load in the task from that should not be met or exceeded. eg -LessThanVersion 2.0.0 will reject anything 2.0.0 or higher, allowing any module in the 1.x.x series.

        .EXAMPLE
        A sample build script is shown below:

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

        The 'default' task is required and should not contain an 'Action' parameter.
        It uses the 'Depends' parameter to specify that 'Test' is a dependency

        The 'Test' task uses the 'Depends' parameter to specify that 'Compile' and 'Clean' are dependencies
        The 'Compile' task depends on the 'Clean' task.

        Note:
        The 'Action' parameter is defaulted to the script block following the 'Clean' task.

        An equivalent 'Test' task is shown below:

        Task Test -Depends Compile, Clean -Action {
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
        Assert
        .LINK
        Exec
        .LINK
        FormatTaskName
        .LINK
        Framework
        .LINK
        Get-PSakeScriptTasks
        .LINK
        Include
        .LINK
        Invoke-psake
        .LINK
        Properties
        .LINK
        TaskSetup
        .LINK
        TaskTearDown
    #>
    [CmdletBinding(DefaultParameterSetName = 'Normal')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Position = 1)]
        [scriptblock]$Action = $null,

        [Parameter(Position = 2)]
        [scriptblock]$PreAction = $null,

        [Parameter(Position = 3)]
        [scriptblock]$PostAction = $null,

        [Parameter(Position = 4)]
        [scriptblock]$PreCondition = {$true},

        [Parameter(Position = 5)]
        [scriptblock]$PostCondition = {$true},

        [Parameter(Position = 6)]
        [switch]$ContinueOnError,

        [ValidateNotNull()]
        [Parameter(Position = 7)]
        [string[]]$Depends = @(),

        [ValidateNotNull()]
        [Parameter(Position = 8)]
        [string[]]$RequiredVariables = @(),

        [Parameter(Position = 9)]
        [string]$Description = $null,

        [Parameter(Position = 10)]
        [string]$Alias = $null,

        [parameter(Mandatory = $true, ParameterSetName = 'SharedTask', Position = 11)]
        [ValidateNotNullOrEmpty()]
        [string]$FromModule,

        [Alias('Version')]
        [parameter(ParameterSetName = 'SharedTask', Position = 12)]
        [string]$RequiredVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 13)]
        [string]$MinimumVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 14)]
        [string]$MaximumVersion,

        [parameter(ParameterSetName = 'SharedTask', Position = 15)]
        [string]$LessThanVersion
    )

    function CreateTask {
        @{
            Name              = $Name
            DependsOn         = $Depends
            PreAction         = $PreAction
            Action            = $Action
            PostAction        = $PostAction
            Precondition      = $PreCondition
            Postcondition     = $PostCondition
            ContinueOnError   = $ContinueOnError
            Description       = $Description
            Duration          = [System.TimeSpan]::Zero
            RequiredVariables = $RequiredVariables
            Alias             = $Alias
            Success           = $true # let's be optimistic
            ErrorMessage      = $null
            ErrorDetail       = $null
            ErrorFormatted    = $null
        }
    }

    # Default tasks have no action
    if ($Name -eq 'default') {
        Assert (!$Action) ($msgs.error_shared_task_cannot_have_action)
    }

    # Shared tasks have no action
    if ($PSCmdlet.ParameterSetName -eq 'SharedTask') {
        Assert (!$Action) ($msgs.error_shared_task_cannot_have_action -f $Name, $FromModule)
    }

    $currentContext = $psake.context.Peek()

    # Dot source the shared task module to load in its tasks
    if ($PSCmdlet.ParameterSetName -eq 'SharedTask') {
        $testModuleParams = @{
            MinimumVersion  = $MinimumVersion
            MaximumVersion  = $MaximumVersion
            LessThanVersion = $LessThanVersion
        }

        if(![string]::IsNullOrEmpty($RequiredVersion)){
            $testModuleParams.MinimumVersion = $RequiredVersion
            $testModuleParams.MaximumVersion = $RequiredVersion
        }

        if ($taskModule = Get-Module -Name $FromModule) {
            # Use the task module that is already loaded into the session
            $testModuleParams.currentVersion  = $taskModule.Version
            $taskModule = Where-Object -InputObject $taskModule -FilterScript {Test-ModuleVersion @testModuleParams}
        } else {
            # Find the module
            $getModuleParams = @{
                ListAvailable = $true
                Name          = $FromModule
                ErrorAction   = 'Ignore'
                Verbose       = $false
            }
            $taskModule = Get-Module @getModuleParams |
                            Where-Object -FilterScript {Test-ModuleVersion -currentVersion $_.Version @testModuleParams} |
                            Sort-Object -Property Version -Descending |
                            Select-Object -First 1
        }

        # This task references a task from a module
        # This reference task "could" include extra data about the task such as
        # additional dependOn, aliase, etc.
        # Store this task to the side so after we load the real task, we can combine
        # this extra data if nesessary
        $referenceTask = CreateTask
        Assert (-not $psake.ReferenceTasks.ContainsKey($referenceTask.Name)) ($msgs.error_duplicate_task_name -f $referenceTask.Name)
        $referenceTaskKey = $referenceTask.Name.ToLower()
        $psake.ReferenceTasks.Add($referenceTaskKey, $referenceTask)

        # Load in tasks from shared module into staging area
        Assert ($null -ne $taskModule) ($msgs.error_unknown_module -f $FromModule)
        $psakeFilePath = Join-Path -Path $taskModule.ModuleBase -ChildPath 'psakeFile.ps1'
        if (-not $psake.LoadedTaskModules.ContainsKey($psakeFilePath)) {
            WriteOutput "Loading tasks from task module [$psakeFilePath]" "debug"
            . $psakeFilePath
            $psake.LoadedTaskModules.Add($psakeFilePath, $null)
        }
    } else {
        # Create new task object
        $newTask = CreateTask
        $taskKey = $newTask.Name.ToLower()

        # If this task was referenced from a parent build script
        # check to see if that reference task has extra data to add
        $refTask = $psake.ReferenceTasks[$taskKey]
        if ($refTask) {

            # Override the PreAction
            if ($refTask.PreAction -ne $newTask.PreAction) {
                $newTask.PreAction = $refTask.PreAction
            }

            # Override the PostAction
            if ($refTask.PostAction -ne $newTask.PostAction) {
                $newTask.PostAction = $refTask.PostAction
            }

            # Override the PreCondition
            if ($refTask.PreCondition -ne $newTask.PreCondition) {
                $newTask.PreCondition = $refTask.PreCondition
            }

            # Override the PostCondition
            if ($refTask.PostCondition -ne $newTask.PostCondition) {
                $newTask.PostCondition = $refTask.PostCondition
            }

            # Override the ContinueOnError
            if ($refTask.ContinueOnError) {
                $newTask.ContinueOnError = $refTask.ContinueOnError
            }

            # Override the Depends
            if ($refTask.DependsOn.Count -gt 0 -and (Compare-Object -ReferenceObject $refTask.DependsOn -DifferenceObject $newTask.DependsOn)) {
                $newTask.DependsOn = $refTask.DependsOn
            }

            # Override the RequiredVariables
            if ($refTask.RequiredVariables.Count -gt 0 -and (Compare-Object -ReferenceObject.RequiredVariables -DifferenceObject $newTask.RequiredVariables)) {
                $newTask.RequiredVariables += $refTask.RequiredVariables
            }
        }

        # Add the task to the context
        Assert (-not $currentContext.tasks.ContainsKey($taskKey)) ($msgs.error_duplicate_task_name -f $taskKey)
        WriteOutput "Adding task [$taskKey)]" "debug"
        $currentContext.tasks[$taskKey] = $newTask

        if ($Alias) {
            $aliasKey = $Alias.ToLower()
            Assert (-not $currentContext.aliases.ContainsKey($aliasKey)) ($msgs.error_duplicate_alias_name -f $Alias)
            $currentContext.aliases[$aliasKey] = $newTask
        }
    }
}
