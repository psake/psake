function Format-ErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $Error[0]
    )

    begin {
        $currentConfig = Get-CurrentConfigurationOrDefault
        $dash = "-" * 70
    }

    process {
        $errorMessage = [System.Text.StringBuilder]::new()
        $date = Get-Date
        if ($currentConfig.VerboseError) {
            $errorMessage.AppendFormat("{0}: An Error Occurred. See Error Details Below:", $date)
            $errorMessage.AppendLine()
            $errorMessage.AppendLine($dash)
            $errorMessage.AppendFormat("Error: {0}", $(Resolve-Error $ErrorRecord -Short))
            $errorMessage.AppendLine()
            $errorMessage.AppendLine($dash)
            $errorMessage.AppendLine($(Resolve-Error $ErrorRecord))
            $errorMessage.AppendLine($dash)
            $errorMessage.AppendLine("Script Variables")
            $errorMessage.AppendLine($dash)
            $errorMessage.AppendLine($(Get-Variable -Scope script | Format-Table | Out-String))
        } else {
            # ($_ | Out-String) gets error messages with source information included.
            $errorMessage.AppendFormat("Error: {0}:", $date)
            $errorMessage.AppendLine()
            $errorMessage.AppendLine("{0}" -f (Resolve-Error $ErrorRecord -Short))
        }
    }

    end {
        $errorMessage.ToString()
    }
}
