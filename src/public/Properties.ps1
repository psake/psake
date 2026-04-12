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

    .PARAMETER Hashtable
    An alternative to the scriptblock parameter, you can provide a hashtable of
    key-value pairs that will be converted into variables. This is useful when
    you want to define properties programmatically or from an external source.

    .EXAMPLE
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
    .EXAMPLE
    Properties {
        $script:build_dir = "c:\build"
        $script:connection_string = "datasource=localhost;initial catalog=northwind;integrated security=sspi"
    }
    Task Compile {
        "Building to: $build_dir"  # No PSScriptAnalyzer warning, variable is recognized
    }

    Recommended: Use script-scoped variables to avoid PSScriptAnalyzer warnings
    The $script: prefix has identical runtime behavior but satisfies
    PSScriptAnalyzer's static analysis requirements.
    .EXAMPLE
    Properties {
        $build_dir = "c:\build"  # Warning: PSUseDeclaredVarsMoreThanAssignments
    }
    Task Compile {
        "Building to: $build_dir"  # Works at runtime, but PSScriptAnalyzer warns
    }

    Alternative: Non-scoped variables (generates PSScriptAnalyzer warnings)

    Variables still work correctly at runtime, but PSScriptAnalyzer cannot detect
    that they will be used in tasks.
    .NOTES
    This works by defining a script block that is pushed onto the
    $psake.Context.Peek().properties stack. This allows the properties to be
    accessed within all tasks in the build script.
    This means that the variables defined in the script block will be
    available in the scope of the tasks, but not in the global scope of the
    build script.

    PSScriptAnalyzer may warn about variables assigned but not used
    (PSUseDeclaredVarsMoreThanAssignments) when variables are declared in
    Properties blocks. This is a false positive - the variables ARE used
    in tasks when the Properties scriptblock is dot-sourced at runtime.

    To suppress this warning, use script-scoped variables:

    Properties {
        $script:build_dir = "c:\build"
        $script:connection_string = "datasource=..."
    }

    This has identical runtime behavior but satisfies PSScriptAnalyzer's
    static analysis requirements. See the examples above for more details.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'ScriptBlock')]
        [scriptblock]$Properties,

        [Parameter(
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Hashtable')]
        [hashtable]$Hashtable
    )

    Write-Debug "Registering Properties block (ParameterSet='$($PSCmdlet.ParameterSetName)')"
    if ($PSCmdlet.ParameterSetName -eq 'Hashtable') {
        # Validate that all keys are legal PowerShell variable names before storing.
        foreach ($key in $Hashtable.Keys) {
            if ($key -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [ArgumentException]::new("Properties hashtable key '$key' is not a valid variable name.", 'Hashtable'),
                    'InvalidPropertyKey',
                    [System.Management.Automation.ErrorCategory]::InvalidArgument,
                    $key
                )
                $PSCmdlet.ThrowTerminatingError($errorRecord)
            }
        }
        # Store the hashtable in $psake so the deferred scriptblock can access it.
        # (closures via GetNewClosure break dot-sourcing into caller's scope)
        # Use Set-Variable at execution time instead of string interpolation to
        # avoid any code-injection risk from key or value content.
        $storageKey = "_propHash_$(Get-Random)"
        $psake[$storageKey] = $Hashtable.Clone()
        $Properties = [scriptblock]::Create("
            foreach (`$_key in `$psake['$storageKey'].Keys) {
                Set-Variable -Name `$_key -Value `$psake['$storageKey'][`$_key]
            }
        ")
    }

    $psake.Context.Peek().properties.Push($Properties)
}
