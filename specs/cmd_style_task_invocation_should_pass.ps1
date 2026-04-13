# Regression test for issue #368.
# Users invoke psake via psake.cmd passing a task name as the first positional
# argument (e.g. "psake.cmd CI 1.0.0"). Invoke-psake detects that the argument
# is not a file, looks up the default build file, and calls Compile-BuildPlan
# with a bare filename ('psakefile.ps1', no directory component).
# Split-Path on a bare filename returns '', causing Join-Path to throw:
#   "Cannot bind argument to parameter 'Path' because it is an empty string."

task default -depends test

task test {
    Push-Location (Join-Path $psake.build_script_dir 'cmd_invocation')
    try {
        # Simulate: psake.cmd default
        # 'default' is treated as BuildFile by Invoke-psake (position 0),
        # which detects it is not a file and falls back to psakefile.ps1.
        Invoke-psake 'default' -NoLogo
    } finally {
        Pop-Location
    }
}
