function Format-ErrorMessage {
    <#
    .SYNOPSIS
    Format an error message for display in psake.

    .DESCRIPTION
    Format an error message for display in psake. The error message includes the error message, error details, and script variables.

    .PARAMETER ErrorRecord
    The error record to format.

    .EXAMPLE
    Format-ErrorMessage -ErrorRecord $Error[0]

    Formats the error message for the first error in the $Error array.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $Error[0]
    )

    begin {
        $currentConfig = Get-CurrentConfigurationOrDefault
        $dash = "-" * 70
    }

    process {
        Write-Debug "Formatting error message (VerboseError=$($currentConfig.VerboseError))"
        $errorMessage = [System.Text.StringBuilder]::new()
        $date = Get-Date
        if ($currentConfig.VerboseError) {
            [void]$errorMessage.AppendFormat("{0}: An Error Occurred. See Error Details Below:", $date)
            [void]$errorMessage.AppendLine()
            [void]$errorMessage.AppendLine($dash)
            [void]$errorMessage.AppendFormat("Error: {0}", $(Resolve-Error $ErrorRecord -Short))
            [void]$errorMessage.AppendLine()
            [void]$errorMessage.AppendLine($dash)
            [void]$errorMessage.AppendLine($(Resolve-Error $ErrorRecord))
            [void]$errorMessage.AppendLine($dash)
            [void]$errorMessage.AppendLine("Script Variables")
            [void]$errorMessage.AppendLine($dash)
            [void]$errorMessage.AppendLine($(Get-Variable -Scope script | Format-Table | Out-String))
        } else {
            # ($_ | Out-String) gets error messages with source information included.
            [void]$errorMessage.AppendFormat("Error: {0}:", $date)
            [void]$errorMessage.AppendLine()
            [void]$errorMessage.AppendLine("{0}" -f (Resolve-Error $ErrorRecord -Short))
        }
        $errorMessage.ToString()
    }
}
