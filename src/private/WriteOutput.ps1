function WriteOutput {
    [CmdLetBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Output,
        [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
        [string]$OutputType = "default"
    )

    Process {
        if ($psake.context.peek().config.outputHandler -is [scriptblock]) {
            & $psake.context.peek().config.outputHandler $Output $OutputType
        }
        else {
            Write-Warning "The psake OutputHandler is invalid. Write-Output will be used."
            Write-Output $Output
        }
    }
}
