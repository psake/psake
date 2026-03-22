@{
    RootModule           = 'psake.psm1'
    ModuleVersion        = '5.0.0'
    GUID                 = 'cfb53216-072f-4a46-8975-ff7e6bda05a5'
    Author               = 'James Kovacs'
    CompanyName          = 'psake'
    Copyright            = 'Copyright (c) 2010-2026 James Kovacs, Damian Hickey, Brandon Olin, and Contributors'
    Description          = @'
psake is a build automation tool written in PowerShell. Define tasks with
dependencies, pre/post conditions, setup/teardown hooks, and input/output
caching. Supports a compile-only mode for inspecting build plans in tests,
structured output for GitHub Actions, and JSON output for tooling integration.
'@
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Core', 'Desktop')

    FunctionsToExport    = @(
        # Execution
        'Invoke-Psake'
        'Invoke-Task'

        # Inspection
        'Get-PSakeScriptTasks'
        'Get-PsakeBuildPlan'
        'Test-PsakeTask'
        'Test-BuildEnvironment'

        # Build script DSL
        'Task'
        'Properties'
        'Include'
        'FormatTaskName'
        'TaskSetup'
        'TaskTearDown'
        'BuildSetup'
        'BuildTearDown'
        'Framework'

        # Utilities
        'Assert'
        'Execute'
        'Version'
        'Clear-PsakeCache'
    )
    CmdletsToExport      = @()
    AliasesToExport      = @()
    VariablesToExport    = @('psake')

    PrivateData          = @{
        PSData = @{
            Prerelease   = 'alpha'
            Tags         = @(
                'Build'
                'Task'
                'Automation'
                'BuildAutomation'
                'TaskRunner'
                'DevOps'
                'CI'
                'ContinuousIntegration'
                'Make'
                'Rake'
                'Deploy'
                'Pipeline'
                'BuildScript'
                'psake'
                'PowerShell'
            )
            LicenseUri   = 'https://raw.githubusercontent.com/psake/psake/main/license.txt'
            ProjectUri   = 'https://github.com/psake/psake'
            IconUri      = 'https://raw.githubusercontent.com/psake/graphics/main/png/psake-single-icon-teal-bg-256x256.png'
            ReleaseNotes = 'https://raw.githubusercontent.com/psake/psake/main/CHANGELOG.md'
        }
    }
}
