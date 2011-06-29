<#
-------------------------------------------------------------------
Defaults
-------------------------------------------------------------------
$config.defaultBuildFileName="default.ps1";
$config.framework = "3.5";
$config.taskNameFormat="Executing {0}";
$config.exitCode="1";
$config.verboseError=$true;
$config.coloredOutput = $false;
$config.modules=(new-object psobject -property @{ autoload=$false })

-------------------------------------------------------------------
Auto-load modules from .\modules folder
-------------------------------------------------------------------
$config.modules=(new-object psobject -property @{ autoload=$true})

-------------------------------------------------------------------
Auto-load modules from .\my_modules folder
-------------------------------------------------------------------
$config.modules=(new-object psobject -property @{ autoload=$true; directory=".\my_modules" })

-------------------------------------------------------------------
Explicitly load module(s)
-------------------------------------------------------------------
$config.modules=(new-object psobject -property @{
    autoload=$false; 
    module=(new-object psobject -property @{path="c:\module1dir\module1.ps1"}), 
           (new-object psobject -property @{path="c:\module1dir\module2.ps1"})
  })
}
#>