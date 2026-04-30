function FormatTaskName {
    <#
    .SYNOPSIS
    This function allows you to change how psake renders the task name during a
    build.

    .DESCRIPTION
    Useful for adding visual separators or color to task names in the
    build output. Accepts a -f format string or a scriptblock that
    receives the task name as its only argument.

    .PARAMETER Format
    A format string or a scriptblock to execute

    .EXAMPLE
    Task default -depends TaskA, TaskB, TaskC
    FormatTaskName "-------- {0} --------"
    Task TaskA {
        "TaskA is executing"
    }
    Task TaskB {
        "TaskB is executing"
    }
    Task TaskC {
        "TaskC is executing"
    }

    A sample build script that uses a format string. The script above produces
    the following output:

    ```
    -------- TaskA --------
    TaskA is executing
    -------- TaskB --------
    TaskB is executing
    -------- TaskC --------
    TaskC is executing

    Build Succeeded!
    ```
    .EXAMPLE
    Task default -depends TaskA, TaskB, TaskC
    FormatTaskName {
        param($taskName)
        write-host "Executing Task: $taskName" -ForegroundColor blue
    }
    Task TaskA {
        "TaskA is executing"
    }
    Task TaskB {
        "TaskB is executing"
    }
    Task TaskC {
        "TaskC is executing"
    }

    A sample build script that uses a ScriptBlock. The above example uses the
    scriptblock parameter to the FormatTaskName function to render each task
    name in the color blue.

    Note: the $taskName parameter name is arbitrary, it could be named anything.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Format
    )

    Write-Debug "Setting task name format to $(if ($Format -is [scriptblock]) { 'scriptblock' } else { "'$Format'" })"
    $psake.Context.Peek().config.taskNameFormat = $Format
}
