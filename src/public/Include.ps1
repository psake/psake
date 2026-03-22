function Include {
    <#
    .SYNOPSIS
    Include the functions or code of another powershell script file into the
    current build script's scope

    .DESCRIPTION
    A build script may declare an "includes" function which allows you to define
    a file containing powershell code to be included and added to the scope of
    the currently running build script. Code from such file will be executed
    after code from build script.

    .PARAMETER Path
    A string containing the path and name of the powershell file to include
    (wildcards can be used)

    .PARAMETER LiteralPath
    A string containing the path and name of the powershell file to include (no
    wildcards)

    .EXAMPLE
    Include ".\build_utils.ps1"
    Task default -depends Test
    Task Test -depends Compile, Clean {
    }
    Task Compile -depends Clean {
    }
    Task Clean {
    }

    The script above includes all the functions and variables defined in the ".\build_utils.ps1" script into the current build script's scope

    Note: You can have more than 1 "Include" function defined in the build script.

    .EXAMPLE
    @("File1.ps1","File2.ps1") | Include
    Get-ChildItem | Include

    Strings or FileInfo objects can be piped to the Include function

    #>
    [CmdletBinding(DefaultParameterSetName = 'Path')]
    param(
        [Parameter(ParameterSetName = 'Path', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        [Alias("fileNamePathToInclude")]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string]$Path,
        [Parameter(ParameterSetName = 'LiteralPath', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LiteralPath
    )

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            [string[]]$resolvedPaths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            [string[]]$resolvedPaths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        foreach ($resolvedPath in $resolvedPaths) {
            Write-Debug "Including file '$resolvedPath'"
            Assert (Test-Path $resolvedPath -PathType Leaf) ($msgs.error_invalid_include_path -f $resolvedPath)

            $psake.Context.Peek().includes.Enqueue($resolvedPath)
        }
    }
}
