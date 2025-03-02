function Format-ErrorMessage {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $Error[0]
    )

    begin {
        $currentConfig = Get-CurrentConfigurationOrDefault
    }

    process {
        if ($currentConfig.VerboseError) {
            $error_message = "{0}: An Error Occurred. See Error Details Below: $($script:nl)" -f (Get-Date)
            $error_message += ("-" * 70) + $script:nl
            $error_message += "Error: {0}$($script:nl)" -f (ResolveError $ErrorRecord -Short)
            $error_message += ("-" * 70) + $script:nl
            $error_message += ResolveError $ErrorRecord
            $error_message += ("-" * 70) + $script:nl
            $error_message += "Script Variables" + $script:nl
            $error_message += ("-" * 70) + $script:nl
            $error_message += Get-Variable -Scope script | Format-Table | Out-String
        } else {
            # ($_ | Out-String) gets error messages with source information included.
            $error_message = "Error: {0}: $($script:nl){1}" -f (Get-Date), (ResolveError $ErrorRecord -Short)
        }
    }

    end {
        $error_message
    }
}
