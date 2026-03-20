function Write-BuildMessage {
    <#
    .SYNOPSIS
    Writes a build message to the console with appropriate formatting.

    .DESCRIPTION
    Replaces the old Write-PsakeOutput/OutputHandler system with direct output.
    Respects $env:NO_COLOR, supports Default/GitHubActions output formats,
    and suppresses output in JSON/Quiet modes.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        "PSAvoidUsingWriteHost",
        "",
        Justification = "This function centralizes all console output for psake, allowing for consistent formatting and color control. Write-Host is necessary here to achieve the desired output behavior across different modes (Default, GitHubActions, JSON, Quiet)."
    )]
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [object]$Message,

        [Parameter(Position = 1)]
        [string]$Type = 'Default'
    )

    process {
        # Suppress output in JSON and Quiet modes
        if ($script:CurrentOutputFormat -eq 'JSON' -or $script:CurrentOutputFormat -eq 'Quiet') {
            return
        }

        # GitHub Actions annotation format
        if ($script:CurrentOutputFormat -eq 'GitHubActions') {
            switch ($Type) {
                'Error' { Write-Host "::error::$Message" }
                'Warning' { Write-Host "::warning::$Message" }
                'Debug' { Write-Host "::debug::$Message" }
                default { Write-Host $Message }
            }
            return
        }

        # Default console output
        $useColor = Test-Path env:NO_COLOR
        if ($Type -eq 'Debug') {
            Write-Debug $Message
            return
        }

        if ($useColor) {
            switch ($Type) {
                'Heading' { Write-Host $Message -ForegroundColor Cyan }
                'Warning' { Write-Host $Message -ForegroundColor Yellow }
                'Error' { Write-Host $Message -ForegroundColor Red }
                'Success' { Write-Host $Message -ForegroundColor Green }
                default { Write-Host $Message }
            }
        } else {
            Write-Host $Message
        }
    }
}
