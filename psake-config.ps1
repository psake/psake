<#
-------------------------------------------------------------------
Defaults
-------------------------------------------------------------------
$psake.config.defaultBuildFileName="default.ps1";
$psake.config.framework = "3.5";
$psake.config.taskNameFormat="Executing {0}";
$psake.config.exitCode="1";
$psake.config.verboseError=$true;
$psake.config.coloredOutput = $false;
$psake.config.modules=(new-object psobject -property @{ autoload=$false })

-------------------------------------------------------------------
Auto-load modules from .\modules folder
-------------------------------------------------------------------
$psake.config.modules=(new-object psobject -property @{ autoload=$true})

-------------------------------------------------------------------
Auto-load modules from .\my_modules folder
-------------------------------------------------------------------
$psake.config.modules=(new-object psobject -property @{ autoload=$true; directory=".\my_modules" })

-------------------------------------------------------------------
Explicitly load module(s)
-------------------------------------------------------------------
$psake.config.modules=(new-object psobject -property @{
    autoload=$false; 
    module=(new-object psobject -property @{path="c:\module1dir\module1.ps1"}), 
           (new-object psobject -property @{path="c:\module1dir\module2.ps1"})
  })
}
#>