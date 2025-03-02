function LoadModules {
    $currentConfig = $psake.Context.peek().config
    if ($currentConfig.modules) {

        $scope = $currentConfig.moduleScope

        $global = [string]::Equals($scope, "global", [StringComparison]::CurrentCultureIgnoreCase)

        $currentConfig.modules | ForEach-Object {
            Resolve-Path $_ | ForEach-Object {
                "Loading module: $_"
                $module = Import-Module $_ -PassThru -DisableNameChecking -Global:$global
                if (!$module) {
                    throw ($msgs.error_loading_module -f $_.Name)
                }
            }
        }

        ""
    }
}
