function Write-BuildAnnotation {
    <#
    .SYNOPSIS
    Emits a GitHub Actions / VS Code problem-matcher annotation line.

    .DESCRIPTION
    Writes a single-line annotation in the GitHub Actions workflow command format:
        ::severity file=<path>,line=<n>,col=<n>,title=<task>::<message>

    Only emits output when the current output format is Annotated or GitHubActions.
    In all other formats this function is a no-op.

    Fields are omitted when empty or zero. Field ordering is fixed (file, line,
    col, title) because the VS Code problem matcher regex depends on it.

    Escaping follows the GitHub Actions workflow command specification:

    Property values (file, title, etc.):
        %  -> %25  (encoded first to avoid double-encoding)
        \r -> %0D
        \n -> %0A
        :  -> %3A
        ,  -> %2C

    Message (data) value:
        %  -> %25
        \r -> %0D
        \n -> %0A
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessage(
        "PSAvoidUsingWriteHost",
        "",
        Justification = "Annotation lines must be plain text with no ANSI color codes. Write-Host without -ForegroundColor satisfies this requirement."
    )]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('error', 'warning')]
        [string] $Severity,

        [string] $File,
        [int]    $Line = 0,
        [int]    $Column = 0,
        [string] $Title,
        [Parameter(Mandatory)]
        [string] $Message
    )

    # No-op for any format that is not Annotated or GitHubActions
    if ($script:CurrentOutputFormat -ne 'Annotated' -and $script:CurrentOutputFormat -ne 'GitHubActions') {
        return
    }

    # Escape per GitHub Actions spec — percent first to avoid double-encoding.
    # Property values need all five escapes; the message (data) needs only three.
    $escapedMessage = $Message -replace '%', '%25' -replace "`r", '%0D' -replace "`n", '%0A'

    # Build optional fields in the fixed order required by the VS Code regex:
    # file, line, col, title
    $fields = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrEmpty($File)) {
        $escapedFile = $File -replace '%', '%25' -replace "`r", '%0D' -replace "`n", '%0A' -replace ':', '%3A' -replace ',', '%2C'
        $fields.Add("file=$escapedFile")
    }
    if ($Line -gt 0) {
        $fields.Add("line=$Line")
    }
    if ($Column -gt 0) {
        $fields.Add("col=$Column")
    }
    if (-not [string]::IsNullOrEmpty($Title)) {
        $escapedTitle = $Title -replace '%', '%25' -replace "`r", '%0D' -replace "`n", '%0A' -replace ':', '%3A' -replace ',', '%2C'
        $fields.Add("title=$escapedTitle")
    }

    if ($fields.Count -gt 0) {
        $annotation = "::$Severity $($fields -join ',')::$escapedMessage"
    } else {
        $annotation = "::$Severity::$escapedMessage"
    }

    # Write-Host without -ForegroundColor ensures no ANSI escape codes.
    # $env:NO_COLOR is intentionally NOT honoured — annotations must always be
    # plain text regardless of colour preferences.
    Write-Host $annotation
}
