function BuildTearDown {
    <#
    .SYNOPSIS
    Adds a scriptblock that will be executed once at the end of the build

    .DESCRIPTION
    Runs after all tasks complete, even if the build failed. Use this for
    cleanup, notifications, or post-build reporting.

    .PARAMETER Setup
    Executed after all tasks finish, whether or not the build succeeded.

    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {}
    Task Compile -Depends Clean {}
    Task Clean {}
    BuildTearDown {
        "Running 'BuildTearDown'"
    }

    The script above produces the following output:

    ```
    Executing task, Clean...
    Executing task, Compile...
    Executing task, Test...
    Running 'BuildTearDown'
    Build Succeeded
    ```
    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {
        throw "forced error"
    }
    Task Compile -Depends Clean {}
    Task Clean {}
    BuildTearDown {
        "Running 'BuildTearDown'"
    }

    The script above produces the following output:

    ```
    Executing task, Clean...
    Executing task, Compile...
    Executing task, Test...
    Running 'BuildTearDown'
    forced error
    At line:x char:x ...
    ```
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Setup
    )

    Write-Debug "Registering BuildTearDown scriptblock"
    $psake.Context.Peek().buildTearDownScriptBlock = $Setup
}
