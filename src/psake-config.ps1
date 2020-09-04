<#
-------------------------------------------------------------------
Defaults
-------------------------------------------------------------------
$config.buildFileName="psakefile.ps1"
$config.legacyBuildFileName="default.ps1"
$config.framework = "4.0"
$config.taskNameFormat="Executing {0}"
$config.verboseError=$false
$config.coloredOutput = $true
$config.modules=$null

-------------------------------------------------------------------
Load modules from .\modules folder and from file my_module.psm1
-------------------------------------------------------------------
$config.modules=(".\modules\*.psm1",".\my_module.psm1")

-------------------------------------------------------------------
Use scriptblock for taskNameFormat and outputHandlers
-------------------------------------------------------------------
$config.taskNameFormat= { param($taskName) "Executing $taskName at $(get-date)" }
$config.outputHandler = {
    [CmdLetBinding()]
    Param (
        [Parameter(Position=0)]
        [object]$Output,
        [Parameter(Position=1)]
        [string]$OutputType = "default"
    )

    Process {
        if ($psake.context.peek().config.outputHandlers.$OutputType -is [scriptblock]) {
            & $psake.context.peek().config.outputHandlers.$OutputType $Output
        }
        elseif ($OutputType -ne "default") {
            Write-Warning "No outputHandler has been defined for $OutputType output. The default outputHandler will be used."
            WriteOutput -Output $Output -OutputType "default"
        }
        else {
            Write-Warning "The default outputHandler is invalid. Write-Output will be used."
            Write-Output $Output
        }
    }
}
$config.outputHandlers = @{
    heading         = { Param($output) WriteColoredOutput $output -foregroundcolor Cyan };
    default         = { Param($output) Write-Output $output };
    debug           = { Param($output) Write-Debug $output };
    warning         = { Param($output) WriteColoredOutput $output -foregroundcolor Yellow };
    error           = { Param($output) WriteColoredOutput $output -foregroundcolor Red };
    success         = { Param($output) WriteColoredOutput $output -foregroundcolor Green };
}
#>
