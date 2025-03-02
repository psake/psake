function Write-ColoredOutput {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $Message,
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]
        $ForegroundColor
    )

    $currentConfig = Get-CurrentConfigurationOrDefault
    if ($currentConfig.coloredOutput -eq $true) {
        if (($null -ne $Host.UI) -and ($null -ne $Host.UI.RawUI) -and ($null -ne $Host.UI.RawUI.ForegroundColor)) {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        }
    }

    $message

    if ($null -ne $previousColor) {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}
