function Write-Documentation {
    [CmdletBinding()]
    param (
        [Parameter()]
        [switch]
        $ShowDetailed
    )

    $currentContext = $psake.Context.Peek()

    if ($currentContext.tasks.default) {
        $defaultTaskDependencies = $currentContext.tasks.default.DependsOn
    } else {
        $defaultTaskDependencies = @()
    }

    $docs = Get-TasksFromContext -CurrentContext $currentContext |
        Where-Object { $_.Name -ne 'default' } |
        ForEach-Object {
            $isDefault = $null
            if ($defaultTaskDependencies -contains $_.Name) {
                $isDefault = $true
            }
            return Add-Member -InputObject $_ 'Default' $isDefault -PassThru
        }

    if ($ShowDetailed) {
        $docs | Sort-Object 'Name' | Format-List -Property Name, Alias, Description, @{Label = "Depends On"; Expression = { $_.DependsOn -join ', ' } }, Default | Write-PsakeOutput
    } else {
        $docs | Sort-Object 'Name' | Format-Table -AutoSize -Wrap -Property Name, Alias, @{Label = "Depends On"; Expression = { $_.DependsOn -join ', ' } }, Default, Description | Write-PsakeOutput
    }
}
