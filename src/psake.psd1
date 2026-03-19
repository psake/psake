@{
    RootModule = 'psake.psm1'
    ModuleVersion = '5.0.0'
    GUID = 'cfb53216-072f-4a46-8975-ff7e6bda05a5'
    Author = 'James Kovacs'
    Copyright = 'Copyright (c) 2010-18 James Kovacs, Damian Hickey, Brandon Olin, and Contributors'
    PowerShellVersion = '5.1'
    Description = 'psake is a build automation tool written in PowerShell.'
    FunctionsToExport = @(
        'Invoke-psake'
        'Invoke-Task'
        'Get-PSakeScriptTasks'
        'Get-PsakeBuildPlan'
        'Test-PsakeTask'
        'Task'
        'Properties'
        'Include'
        'FormatTaskName'
        'TaskSetup'
        'TaskTearDown'
        'Framework'
        'Assert'
        'Exec'
        'Version'
        'Clear-PsakeCache'
    )
    VariablesToExport = 'psake'
    PrivateData = @{
        PSData = @{
            ReleaseNotes = 'https://raw.githubusercontent.com/psake/psake/main/CHANGELOG.md'
            LicenseUri = 'https://raw.githubusercontent.com/psake/psake/main/license.txt'
            ProjectUri = 'https://github.com/psake/psake'
            Tags = @('Build', 'Task')
            IconUri = 'https://raw.githubusercontent.com/psake/graphics/main/png/psake-single-icon-teal-bg-256x256.png'
        }
    }
}
