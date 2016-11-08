task default -depends test

task test {
    # This test fixture has a legacy default build file.

    Push-Location 'legacy_build_file'
    $result = invoke-psake -Docs | Out-String
    Pop-Location

    Assert ($result -match 'alegacydefaulttask') 'Default build file should a task called alegacydefaulttask'
}