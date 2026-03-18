function Write-ColoredOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Message,
        [Parameter(Mandatory = $false)]
        [System.ConsoleColor]
        $ForegroundColor = $Host.UI.RawUI.ForegroundColor
    )

    $currentConfig = Get-CurrentConfigurationOrDefault
    if ($currentConfig.coloredOutput -eq $true) {
        if (($null -ne $Host.UI) -and ($null -ne $Host.UI.RawUI) -and ($null -ne $Host.UI.RawUI.ForegroundColor)) {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        }
    }

    # Need to write-host for plain text, but write-output for things like tables
    if ($Message -is [string]) {
        Write-Host $Message
    } else {
        Write-Output $Message
    }

    if ($null -ne $previousColor) {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}
