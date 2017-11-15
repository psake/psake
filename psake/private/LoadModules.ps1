function LoadModules {
    $currentConfig = $psake.context.peek().config
    if ($currentConfig.modules) {

        $scope = $currentConfig.moduleScope

        $global = [string]::Equals($scope, "global", [StringComparison]::CurrentCultureIgnoreCase)

        $currentConfig.modules | foreach {
            resolve-path $_ | foreach {
                "Loading module: $_"
                $module = import-module $_ -passthru -DisableNameChecking -global:$global
                if (!$module) {
                    throw ($msgs.error_loading_module -f $_.Name)
                }
            }
        }
        ""
    }
}
