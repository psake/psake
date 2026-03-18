function Get-DefaultPsakeConfig {
    param (
    )
    $psake = @{}

    $psake.version = $manifest.Version.ToString()
    $psake.Context = New-Object system.collections.stack # holds onto the current state of all variables
    $psake.run_by_psake_build_tester = $false # indicates that build is being run by psake-BuildTester
    $psake.LoadedTaskModules = @{}
    $psake.ReferenceTasks = @{}

    # TODO: Replace New-Object with [PSCustomObject] when dropping support for PowerShell 2.0
    #region Default Psake Configuration
    # Contains default configuration, can be overridden in psake-config.ps1 in
    # directory with psake.psm1 or in directory with current build script
    $psake.ConfigDefault = New-Object 'PSObject' -Property @{
        BuildFileName       = "psakefile.ps1"
        LegacyBuildFileName = "default.ps1"
        Framework           = "4.0"
        TaskNameFormat      = "Executing {0}"
        VerboseError        = $False
        ColoredOutput       = $True
        Modules             = $Null
        ModuleScope         = ""
        OutputHandler       = {
            [CmdLetBinding()]
            param (
                [Parameter(Position = 0)]
                [object]$Output,
                [Parameter(Position = 1)]
                [string]$OutputType = 'Default'
            )

            process {
                if ($psake.Context.peek().config.OutputHandlers.$OutputType -is [scriptblock]) {
                    & $psake.Context.peek().config.OutputHandlers.$OutputType $Output
                } elseif ($OutputType -ne "default") {
                    Write-Warning "No OutputHandler has been defined for $OutputType output. The default OutputHandler will be used."
                    Write-PsakeOutput -Output $Output -OutputType 'default'
                } else {
                    Write-Warning "The default OutputHandler is invalid. Write-Host will be used."
                    # We use Write-Host because this should not output something that is captured by a variable
                    Write-Host $Output
                }
            }
        }
        OutputHandlers      = @{
            Heading = {
                param($Output)
                Write-ColoredOutput -Message $Output -ForegroundColor 'Cyan'
            }
            Default = {
                param($Output)
                Write-ColoredOutput -Message $Output -ForegroundColor 'White'
            }
            Debug   = {
                param($Output)
                Write-Debug $Output
            }
            Warning = {
                param($Output)
                Write-ColoredOutput -Message $Output -ForegroundColor 'Yellow'
            }
            Error   = {
                param($Output)
                Write-ColoredOutput -Message $Output -ForegroundColor 'Red'
            }
            Success = {
                param($Output)
                Write-ColoredOutput -Message $Output -ForegroundColor 'Green'
            }
        }
    }
    #endregion

    $psake.build_success = $false # indicates that the current build was successful
    $psake.build_script_file = $null # contains a System.IO.FileInfo for the current build script
    $psake.build_script_dir = "" # contains a string with fully-qualified path to current build script
    $psake.error_message = $null # contains the error message which caused the script to fail
    $psake.error_record = $null # contains the full ErrorRecord object for programmatic inspection
    return $psake
}
