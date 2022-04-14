function Exec {
    <#
        .SYNOPSIS
        Helper function for executing command-line programs.

        .DESCRIPTION
        This is a helper function that runs a scriptblock and checks the PS variable $lastexitcode to see if an error occcured.
        If an error is detected then an exception is thrown.
        This function allows you to run command-line programs without having to explicitly check fthe $lastexitcode variable.

        .PARAMETER Cmd
        The scriptblock to execute. This scriptblock will typically contain the command-line invocation.

        .PARAMETER ErrorMessage
        The error message to display if the external command returned a non-zero exit code.

        .PARAMETER MaxRetries
        The maximum number of times to retry the command before failing.

        .PARAMETER RetryTriggerErrorPattern
        If the external command raises an exception, match the exception against this regex to determine if the command can be retried.
        If a match is found, the command will be retried provided [MaxRetries] has not been reached.

        .PARAMETER workingDirectory
        The working directory to set before running the external command.

        .EXAMPLE
        exec { svn info $repository_trunk } "Error executing SVN. Please verify SVN command-line client is installed"

        This example calls the svn command-line client.
        .LINK
        Assert
        .LINK
        FormatTaskName
        .LINK
        Framework
        .LINK
        Get-PSakeScriptTasks
        .LINK
        Include
        .LINK
        Invoke-psake
        .LINK
        Properties
        .LINK
        Task
        .LINK
        TaskSetup
        .LINK
        TaskTearDown
        .LINK
        Properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Cmd,

        [string]$ErrorMessage = ($msgs.error_bad_command -f $Cmd),

        [int]$MaxRetries = 0,

        [string]$RetryTriggerErrorPattern = $null,

        [Alias("wd")]
        [string]$workingDirectory = $null
    )

    $tryCount = 1

    do {
        try {

            if ($workingDirectory) {
                Push-Location -Path $workingDirectory
            }

            $global:lastexitcode = 0
            & $Cmd
            if ($global:lastexitcode -ne 0) {
                throw "Exec: $ErrorMessage"
            }
            break
        }
        catch [Exception] {
            if ($tryCount -gt $MaxRetries) {
                throw $_
            }

            if ($RetryTriggerErrorPattern -ne $null) {
                $isMatch = [regex]::IsMatch($_.Exception.Message, $RetryTriggerErrorPattern)

                if ($isMatch -eq $false) {
                    throw $_
                }
            }

            "Try $tryCount failed, retrying again in 1 second..."

            $tryCount++

            [System.Threading.Thread]::Sleep([System.TimeSpan]::FromSeconds(1))
        }
        finally {
            if ($workingDirectory) {
                Pop-Location
            }
        }
    }
    while ($true)
}
