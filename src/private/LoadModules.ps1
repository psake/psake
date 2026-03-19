function LoadModules {
    [CmdletBinding()]
    param()

    $currentConfig = $psake.Context.peek().config
    if ($currentConfig.modules) {
        $scope = $currentConfig.moduleScope
        $global = [string]::Equals($scope, "global", [StringComparison]::CurrentCultureIgnoreCase)
        Write-Debug "Loading modules with scope '$scope' (global=$global)"

        $currentConfig.modules | ForEach-Object {
            Resolve-Path $_ | ForEach-Object {
                Write-Debug "Loading module: $_"
                "Loading module: $_"
                $module = Import-Module $_ -PassThru -DisableNameChecking -Global:$global
                if (!$module) {
                    throw ($msgs.error_loading_module -f $_.Name)
                }
            }
        }

        ""
    } else {
        Write-Debug "No modules configured to load"
    }
}
