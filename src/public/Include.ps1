function Include {
    <#
    .SYNOPSIS
    Include the functions or code of another powershell script file into the
    current build script's scope

    .DESCRIPTION
    Included scripts are dot-sourced into the build script's scope after
    the build file finishes loading. You can call Include more than once.

    .PARAMETER Path
    Path to the script file(s) to include. Supports wildcards.

    .PARAMETER LiteralPath
    Path to the script file to include. No wildcard expansion.

    .INPUTS
    System.String

    The path(s) to the script file(s) to include in the build.

    .EXAMPLE
    Include ".\build_utils.ps1"
    Task default -depends Test
    Task Test -depends Compile, Clean {
    }
    Task Compile -depends Clean {
    }
    Task Clean {
    }

    Includes all functions and variables from build_utils.ps1 in the
    build script's scope.

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
