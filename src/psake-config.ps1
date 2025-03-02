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
        if ($psake.Context.peek().config.outputHandlers.$OutputType -is [scriptblock]) {
            & $psake.Context.peek().config.outputHandlers.$OutputType $Output
        }
        elseif ($OutputType -ne "default") {
            Write-Warning "No outputHandler has been defined for $OutputType output. The default outputHandler will be used."
            Write-PsakeOutput -Output $Output -OutputType "default"
        }
        else {
            Write-Warning "The default outputHandler is invalid. Write-Output will be used."
            Write-Output $Output
        }
    }
}
$config.outputHandlers = @{
    heading         = { Param($output) Write-ColoredOutput $output -foregroundcolor Cyan };
    default         = { Param($output) Write-Output $output };
    debug           = { Param($output) Write-Debug $output };
    warning         = { Param($output) Write-ColoredOutput $output -foregroundcolor Yellow };
    error           = { Param($output) Write-ColoredOutput $output -foregroundcolor Red };
    success         = { Param($output) Write-ColoredOutput $output -foregroundcolor Green };
}
#>
