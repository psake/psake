task default -depends test

task test {
    # This test fixture has both a default and legacy default build file.
    # In this case the default buildfile should be used in preference to legacy
    
    Push-Location 'legacy_and_default_build_file'
    $result = invoke-psake -Docs | Out-String
    Pop-Location

    Assert ($result -match 'adefaulttask') 'Default build file should a task called adefaulttask'
}