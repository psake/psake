function Restore-Environment {
    [CmdletBinding()]
    param ()
    if ($psake.Context.Count -eq 0) {
        return
    }
    $currentContext = $psake.Context.Peek()
    Write-Debug "Restoring path to: $($currentContext.originalEnvPath)"
    $env:PATH = $currentContext.originalEnvPath

    Write-Debug "Restoring location to: $($currentContext.originalDirectory)"
    Set-Location $currentContext.originalDirectory

    Write-Debug "Restoring error action preference to: $($currentContext.originalErrorActionPreference)"
    $global:ErrorActionPreference = $currentContext.originalErrorActionPreference

    Write-Debug "Resetting loaded modules and reference tasks"
    $psake.LoadedTaskModules = @{}
    $psake.ReferenceTasks = @{}
    [void] $psake.Context.Pop()
}
