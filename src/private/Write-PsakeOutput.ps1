function Write-PsakeOutput {
    [CmdLetBinding()]
    Param (
        [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [object]$Output,
        [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
        [OutputTypes]$OutputType = 'Default'
    )

    Process {
        if ($psake.Context.peek().config.outputHandler -is [scriptblock]) {
            & $psake.Context.peek().config.outputHandler $Output $OutputType
        } else {
            Write-Warning "The psake OutputHandler is invalid. Write-Output will be used."
            Write-Output $Output
        }
    }
}
