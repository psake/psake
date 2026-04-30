
function TaskTearDown {
    <#
    .SYNOPSIS
    Adds a scriptblock to the build that will be executed after each task

    .DESCRIPTION
    Use this for per-task teardown such as logging duration, checking
    postconditions, or cleaning up temporary state. The completed
    [PsakeTask] is passed as an optional argument with success/error info.

    .PARAMETER TearDown
    Receives the completed task as an optional [PsakeTask] argument.

    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {
    }
    Task Compile -Depends Clean {
    }
    Task Clean {
    }
    TaskTearDown {
        "Running 'TaskTearDown' for task $context.Peek().currentTaskName"
    }
    The script above produces the following output:

    ```
    Executing task, Clean...
    Running 'TaskTearDown' for task Clean
    Executing task, Compile...
    Running 'TaskTearDown' for task Compile
    Executing task, Test...
    Running 'TaskTearDown' for task Test

    Build Succeeded
    ```

    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {}
    Task Compile -Depends Clean {}
    Task Clean {}
    TaskTearDown {
        param($task)
        if ($task.Success) {
            "Running 'TaskTearDown' for task $($task.Name) - success!"
        } else {
            "Running 'TaskTearDown' for task $($task.Name) - failed: $($task.ErrorMessage)"
        }
    }

    The script above produces the following output:

    ```
    Executing task, Clean...
    Running 'TaskTearDown' for task Clean - success!
    Executing task, Compile...
    Running 'TaskTearDown' for task Compile - success!
    Executing task, Test...
    Running 'TaskTearDown' for task Test - success!

    Build Succeeded
    ```
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$TearDown
    )

    Write-Debug "Registering TaskTearDown scriptblock"
    $psake.Context.Peek().taskTearDownScriptBlock = $TearDown
}
