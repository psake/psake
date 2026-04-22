# Regression test for issue #372.
# External commands must run with stdout connected to the console (TTY),
# not through an intermediate PowerShell pipeline stage. ANSI-aware tools
# detect piping via Console.IsOutputRedirected and disable colors when True.
#
# The assertion is skipped when the test environment itself has redirected
# stdout (e.g. CI runners), where True is the expected baseline regardless.

$script:ansiOutputDir  = Join-Path $psake.build_script_dir 'ansi_output'
$script:ansiCsproj     = Join-Path $script:ansiOutputDir 'AnsiCheck.csproj'
$script:resultFile     = [IO.Path]::GetTempFileName()

Task default -Depends Build, TaskWrapped, ExecWrapped, Verify

Task Build {
    Exec { dotnet build $script:ansiCsproj --nologo -v quiet }
}

Task TaskWrapped {
    & dotnet run --project $script:ansiCsproj --no-build -- $script:resultFile
}

Task ExecWrapped {
    Exec { dotnet run --project $script:ansiCsproj --no-build }
}

Task Verify {
    $result = (Get-Content $script:resultFile -Raw -ErrorAction SilentlyContinue).Trim()
    Remove-Item $script:resultFile -ErrorAction SilentlyContinue

    if ([Console]::IsOutputRedirected) {
        Write-Warning "Stdout already redirected in this environment; TTY assertion skipped."
        return
    }
    Assert ($result -eq 'False') (
        "Expected Console.IsOutputRedirected=False (TTY preserved) but got '$result'. " +
        "Regression: stdout is being piped through psake, breaking ANSI output (issue #372)."
    )
}
