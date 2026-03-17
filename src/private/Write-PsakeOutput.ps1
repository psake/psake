function Write-PsakeOutput {
    <#
    .SYNOPSIS
    Write Output using specific Output handlers

    .DESCRIPTION
    Allow users to supply different output handlers to change color
    or other things.

    .PARAMETER Output
    The object to output.

    .PARAMETER OutputType
    The type of Output. Options: Default, Error, Heading, Debug, Warning,
    Success. The output handler for the specified type will be used if it
    exists; otherwise, the default output handler will be used.

    .EXAMPLE
    Write-PsakeOutput -Output "This is a heading" -OutputType "Heading"

    Write a heading message using the Heading output handler.
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [object]
        $Output,
        [Parameter(
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [OutputTypes]
        $OutputType = 'Default'
    )

    begin {
        $handler = { param($Output) Write-Output $Output }
        # Check if we're in a psake context; if not, just write to output and exit.
        if (
            $psake.Context.Count -eq 0 -or
            $null -eq $psake.Context.peek().config -or
            $null -eq $psake.Context.peek().config.outputHandlers
        ) {
            Write-Warning "No psake context found. Write-PsakeOutput will write to standard output."
        } elseif (-not $psake.Context.peek().config.outputHandlers.ContainsKey($OutputType)) {
            Write-Warning "No output handler defined for '$OutputType'."
        } else {
            $configured = $psake.Context.peek().config.outputHandlers[$OutputType]
            if ($configured -is [scriptblock]) {
                $handler = $configured
            } else {
                Write-Warning "The psake OutputHandler for '$OutputType' is invalid. Write-Output will be used."
            }
        }
    }

    process {
        $handler.Invoke($Output)
    }
}
