function Write-BuildMessage {
    <#
    .SYNOPSIS
    Writes a build message to the console with appropriate formatting.

    .DESCRIPTION
    Replaces the old Write-PsakeOutput/OutputHandler system with direct output.
    Respects $env:NO_COLOR, supports Default/GitHubActions/Annotated output
    formats, and suppresses output in JSON/Quiet modes. Annotated mode emits
    colored console output (same as Default) plus bare annotation lines for
    errors and warnings via Write-BuildAnnotation.
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

        # Default console output (also used as the human-readable layer for Annotated mode)
        $useColor = -not (Test-Path env:NO_COLOR)
        if ($Type -eq 'Debug') {
            Write-Debug $Message
            return
        }

        if ($Type -eq 'Verbose') {
            Write-Verbose $Message
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

        # Annotated mode: also emit a bare annotation line for errors and warnings
        # so secondary matchers can pick them up. Informational types (Heading,
        # Success, etc.) are intentionally skipped — only failures belong in the
        # Problems panel. Positioned annotations with file/line are emitted
        # separately by Invoke-BuildPlan when an error record is available.
        if ($script:CurrentOutputFormat -eq 'Annotated') {
            switch ($Type) {
                'Error'   { Write-BuildAnnotation -Severity 'error'   -Message $Message }
                'Warning' { Write-BuildAnnotation -Severity 'warning' -Message $Message }
            }
        }
    }
}
