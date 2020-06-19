$config.outputHandler = {
    [CmdLetBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Output,
        [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
        [string]$OutputType = "default"
    )

    Process {
        Write-Output "WriteOutput: $OutputType : $Output"
    }
};
