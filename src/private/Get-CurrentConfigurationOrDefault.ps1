function Get-CurrentConfigurationOrDefault {
    [CmdletBinding()]
    param ()
    if ($psake.Context.count -eq 0) {
        Write-Debug "No configuration found. Using default configuration."
        return $psake.ConfigDefault
    } else {
        Write-Debug "Using configuration from current context."
        return $psake.Context.peek().config
    }
}
