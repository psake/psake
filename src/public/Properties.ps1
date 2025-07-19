function Properties {
    <#
    .SYNOPSIS
    Define a scriptblock that contains assignments to variables that will be
    available within all tasks in the build script

    .DESCRIPTION
    A build script may declare a "Properties" function which allows you to
    define variables that will be available within all the "Task" functions in
    the build script.

    .PARAMETER Properties
    The script block containing all the variable assignment statements

    .EXAMPLE
    A sample build script is shown below:

    Properties {
        $build_dir = "c:\build"
        $connection_string = "datasource=localhost;initial catalog=northwind;integrated security=sspi"
    }

    Task default -depends Test

    Task Test -depends Compile, Clean {
    }

    Task Compile -depends Clean {
    }

    Task Clean {
    }

    Note: You can have more than one "Properties" function defined in the build script.

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
    Task
    .LINK
    TaskSetup
    .LINK
    TaskTearDown
    .NOTES
    This works by defining a script block that is pushed onto the
    $psake.Context.Peek().properties stack. This allows the properties to be
    accessed within all tasks in the build script.
    This means that the variables defined in the script block will be
    available in the scope of the tasks, but not in the global scope of the
    build script.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $Properties
    )

    $psake.Context.Peek().properties.Push($Properties)
}
