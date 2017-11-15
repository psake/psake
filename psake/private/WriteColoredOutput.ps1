function WriteColoredOutput {
    param(
        [string] $message,
        [System.ConsoleColor] $foregroundcolor
    )

    $currentConfig = GetCurrentConfigurationOrDefault
    if ($currentConfig.coloredOutput -eq $true) {
        if (($Host.UI -ne $null) -and ($Host.UI.RawUI -ne $null) -and ($Host.UI.RawUI.ForegroundColor -ne $null)) {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $foregroundcolor
        }
    }

    $message

    if ($previousColor -ne $null) {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}
