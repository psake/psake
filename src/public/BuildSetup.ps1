function BuildSetup {
    <#
        .SYNOPSIS
        Adds a scriptblock that will be executed once at the beginning of the build
        .DESCRIPTION
        This function will accept a scriptblock that will be executed once at the beginning of the build.
        .PARAMETER Setup
        A scriptblock to execute
        .EXAMPLE
        A sample build script is shown below:
        Task default -Depends Test
        Task Test -Depends Compile, Clean {
        }
        Task Compile -Depends Clean {
        }
        Task Clean {
        }
        BuildSetup {
            "Running 'BuildSetup'"
        }
        The script above produces the following output:
        Running 'BuildSetup'
        Executing task, Clean...
        Executing task, Compile...
        Executing task, Test...
        Build Succeeded
        .LINK
        Assert
        .LINK
        Exec
        .LINK
        FormatTaskName
        .LINK
        Framework
        .LINK
        Invoke-psake
        .LINK
        Properties
        .LINK
        Task
        .LINK
        BuildTearDown
        .LINK
         TaskSetup
         .LINK
         TaskTearDown
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Setup
    )

    $psake.Context.Peek().buildSetupScriptBlock = $Setup
}
