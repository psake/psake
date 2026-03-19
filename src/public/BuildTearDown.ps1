function BuildTearDown {
    <#
    .SYNOPSIS
    Adds a scriptblock that will be executed once at the end of the build
    .DESCRIPTION
    This function will accept a scriptblock that will be executed once at the
    end of the build, regardless of success or failure
    .PARAMETER Setup
    A scriptblock to execute
    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {
    }
    Task Compile -Depends Clean {
    }
    Task Clean {
    }
    BuildTearDown {
        "Running 'BuildTearDown'"
    }

    The script above produces the following output:
    Executing task, Clean...
    Executing task, Compile...
    Executing task, Test...
    Running 'BuildTearDown'
    Build Succeeded
    .EXAMPLE
    Task default -Depends Test
    Task Test -Depends Compile, Clean {
        throw "forced error"
    }
    Task Compile -Depends Clean {
    }
    Task Clean {
    }
    BuildTearDown {
        "Running 'BuildTearDown'"
    }

    The script above produces the following output:
    Executing task, Clean...
    Executing task, Compile...
    Executing task, Test...
    Running 'BuildTearDown'
    forced error
    At line:x char:x ...
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Setup
    )

    $psake.Context.Peek().buildTearDownScriptBlock = $Setup
}
