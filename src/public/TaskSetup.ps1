function TaskSetup {
    <#
    .SYNOPSIS
    Adds a scriptblock that will be executed before each task

    .DESCRIPTION
    Use this for per-task setup that applies across all tasks, such as
    logging, timing, or environment checks. The scriptblock receives the
    current [PsakeTask] as an optional argument.

    .PARAMETER Setup
    Receives the current task as an optional [PsakeTask] argument.

    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {
    }
    Task Compile -Depends Clean {
    }
    Task Clean {
    }
    TaskSetup {
        "Running 'TaskSetup' for task $context.Peek().currentTaskName"
    }

    The script above produces the following output:

    ```
    Running 'TaskSetup' for task Clean
    Executing task, Clean...
    Running 'TaskSetup' for task Compile
    Executing task, Compile...
    Running 'TaskSetup' for task Test
    Executing task, Test...

    Build Succeeded
    ```
    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {}
    Task Compile -Depends Clean {}
    Task Clean {}
    TaskSetup {
        param($task)
        "Running 'TaskSetup' for task $($task.Name)"
    }

    The script above produces the following output:

    ```
    Running 'TaskSetup' for task Clean
    Executing task, Clean...
    Running 'TaskSetup' for task Compile
    Executing task, Compile...
    Running 'TaskSetup' for task Test
    Executing task, Test...

    Build Succeeded
    ```
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Setup
    )

    Write-Debug "Registering TaskSetup scriptblock"
    $psake.Context.Peek().taskSetupScriptBlock = $Setup
}
