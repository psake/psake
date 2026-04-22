function Execute {
    <#
    .SYNOPSIS
    Helper function for executing command-line programs.

    .DESCRIPTION
    This is a helper function that runs a scriptblock and checks the PS variable
    $lastexitcode to see if an error occured.

    If an error is detected then an exception is thrown.
    This function allows you to run command-line programs without having to
    explicitly check the $lastexitcode variable.

    .PARAMETER Cmd
    The scriptblock to execute. This scriptblock will typically contain the
    command-line invocation.

    .PARAMETER ErrorMessage
    The error message to display if the external command returned a non-zero
    exit code.

    .PARAMETER MaxRetries
    The maximum number of times to retry the command before failing.

    .PARAMETER RetryTriggerErrorPattern
    If the external command raises an exception, match the exception against
    this regex to determine if the command can be retried. If a match is found,
    the command will be retried provided [MaxRetries] has not been reached.

    .PARAMETER WorkingDirectory
    The working directory to set before running the external command.

    .PARAMETER NewProcess
    If set, the command will be executed in a new process. This can be used to
    isolate the command's environment from the current process.

    .PARAMETER TimeoutSeconds
    If set, the command will be terminated if it runs longer than this number of
    seconds. Defaults to 300 seconds (5 minutes).

    .EXAMPLE
    Execute { svn info $repository_trunk } "Error executing SVN. Please verify SVN command-line client is installed"

    This example calls the svn command-line client.
    #>
    [CmdletBinding()]
    [Alias("Exec")]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Cmd,

        [string]$ErrorMessage = ($msgs.error_bad_command -f $Cmd.ToString().Trim()),

        [int]$MaxRetries = 0,

        [string]$RetryTriggerErrorPattern = $null,

        [Alias("wd")]
        [string]$WorkingDirectory = $null,

        [switch]$NewProcess,

        [int]$TimeoutSeconds = 300
    )

    Write-Debug "Exec: running command$(if ($WorkingDirectory) { " in '$WorkingDirectory'" })$(if ($MaxRetries -gt 0) { " (max retries: $MaxRetries)" })"
    $tryCount = 1

    do {
        try {

            if ($WorkingDirectory) {
                Push-Location -Path $WorkingDirectory
            }

            $global:lastexitcode = 0
            if ($NewProcess.IsPresent) {
                # Determine which PowerShell executable to use based on the
                # current edition (Desktop vs Core)
                if ($PSVersionTable.PSEdition -eq 'Core') {
                    $psExe = 'pwsh'
                } else {
                    $psExe = 'powershell'
                }
                # Convert the scriptblock to a string and execute it in a new
                # process. This is necessary because ProcessStartInfo does not
                # support scriptblocks directly. GetNewClosure() is used to
                # capture the current variable scope and make those variables
                # available in the new process.
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = $psExe
                $startInfo.Arguments = "-Command & { {0} }" -f $Cmd.GetNewClosure().ToString()
                $startInfo.RedirectStandardOutput = $true
                $startInfo.RedirectStandardError = $true
                $startInfo.UseShellExecute = $false
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $startInfo
                $process.Start() | Out-Null
                if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
                    $process.Kill()
                    # Plain throw (not ThrowTerminatingError): the surrounding
                    # catch runs the retry loop — a terminating error would
                    # short-circuit -MaxRetries.
                    throw "Exec: $ErrorMessage (timeout)"
                }
                if ($process.ExitCode -ne 0) {
                    Write-BuildMessage ($msgs.exec_standard_output -f $process.StandardOutput.ReadToEnd()) "Default"
                    Write-BuildMessage ($msgs.exec_standard_error -f $process.StandardError.ReadToEnd()) "Error"
                    # Plain throw: feeds the retry loop (see above).
                    throw "Exec: $ErrorMessage (exit code: $($process.ExitCode))"
                }
                Write-BuildMessage ($msgs.exec_standard_output -f $process.StandardOutput.ReadToEnd()) "Default"
            } else {
                $isOutputSuppressed = $script:CurrentOutputFormat -in @('JSON', 'Quiet')
                if ($isOutputSuppressed) {
                    # Suppress mode: capture stdout and stderr so the caller's $null = context
                    # can discard them; stdout is included in error messages since it was never shown.
                    $stdErr = [System.Collections.ArrayList]@()
                    $stdOut = [System.Collections.ArrayList]@()
                    & $Cmd 2>&1 | ForEach-Object {
                        if ($_ -is [System.Management.Automation.ErrorRecord]) {
                            [void]$stdErr.Add($_)
                        } else {
                            [void]$stdOut.Add($_)
                            $_
                        }
                    }
                    if ($global:lastexitcode -ne 0) {
                        $errMsg = "Exec: $($ErrorMessage.Trim()) (exit code: $global:lastexitcode)"
                        $combinedOutput = @()
                        if ($stdOut.Count -gt 0) {
                            $combinedOutput += ($stdOut | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
                        }
                        if ($stdErr.Count -gt 0) {
                            $combinedOutput += ($stdErr | ForEach-Object { $_.ToString() }) -join [Environment]::NewLine
                        }
                        if ($combinedOutput.Count -gt 0) {
                            $outputText = $combinedOutput -join [Environment]::NewLine
                            Write-BuildMessage ($msgs.exec_standard_error -f $outputText) "Error"
                            $errMsg += "`n$outputText"
                        }
                        $innerException = $null
                        $innerRecord = $null
                        if ($stdErr.Count -gt 0) {
                            $innerRecord = $stdErr[0]
                            $innerException = $innerRecord.Exception
                        }
                        $exception = [System.Management.Automation.RuntimeException]::new(
                            $errMsg, $innerException, $innerRecord
                        )
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $exception,
                            'ExecCommandFailed',
                            [System.Management.Automation.ErrorCategory]::InvalidResult,
                            $Cmd
                        )
                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }
                } else {
                    # Non-suppress mode: stdout goes directly to the console so external
                    # processes see a real TTY and ANSI/color output is preserved.
                    # Only stderr is captured (via temp file) for error messages.
                    $stderrPath = [System.IO.Path]::GetTempFileName()
                    $stderrContent = $null
                    try {
                        & $Cmd 2>$stderrPath
                    } finally {
                        $stderrContent = Get-Content $stderrPath -Raw -ErrorAction SilentlyContinue
                        Remove-Item $stderrPath -ErrorAction SilentlyContinue
                    }
                    if ($global:lastexitcode -ne 0) {
                        $errMsg = "Exec: $($ErrorMessage.Trim()) (exit code: $global:lastexitcode)"
                        if ($stderrContent) {
                            Write-BuildMessage ($msgs.exec_standard_error -f $stderrContent) "Error"
                            $errMsg += "`n$stderrContent"
                        }
                        $exception = [System.Management.Automation.RuntimeException]::new($errMsg)
                        $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                            $exception,
                            'ExecCommandFailed',
                            [System.Management.Automation.ErrorCategory]::InvalidResult,
                            $Cmd
                        )
                        $PSCmdlet.ThrowTerminatingError($errorRecord)
                    }
                }
            }
            break
        } catch [Exception] {
            if ($tryCount -gt $MaxRetries) {
                # Blanket rethrow after retries are exhausted: preserve the
                # original ErrorRecord from the command that actually failed.
                throw $_
            }

            if ($RetryTriggerErrorPattern -ne $null) {
                $isMatch = [regex]::IsMatch($_.Exception.Message, $RetryTriggerErrorPattern)

                if ($isMatch -eq $false) {
                    # Blanket rethrow: error didn't match the retry pattern, so
                    # surface the original failure unmodified.
                    throw $_
                }
            }

            Write-BuildMessage ($msgs.retrying_execute -f $tryCount) "Warning"
            $tryCount++

            [System.Threading.Thread]::Sleep([System.TimeSpan]::FromSeconds(1))
        } finally {
            if ($WorkingDirectory) {
                Pop-Location
            }
        }
    }
    while ($true)
}
