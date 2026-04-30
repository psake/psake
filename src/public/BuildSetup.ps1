function BuildSetup {
    <#
    .SYNOPSIS
    Adds a scriptblock that will be executed once at the beginning of the build

    .DESCRIPTION
    Runs once before the first task executes. Use this to set up shared
    state, logging, or environment validation for the whole build.

    .PARAMETER Setup
    Executed once before any tasks run.

    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {}
    Task Compile -Depends Clean {}
    Task Clean {}
    BuildSetup {
        "Running 'BuildSetup'"
    }

    The script above produces the following output:

    ```
    Running 'BuildSetup'
    Executing task, Clean...
    Executing task, Compile...
    Executing task, Test...
    Build Succeeded
    ```
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Setup
    )

    Write-Debug "Registering BuildSetup scriptblock"
    $psake.Context.Peek().buildSetupScriptBlock = $Setup
}
