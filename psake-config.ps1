#-------------------------------------------------------------------
#Specify defaults and do not auto-load modules
#-------------------------------------------------------------------
$psake.config = new-object psobject -property @{
  defaultbuildfilename="default.ps1";
  tasknameformat="Executing {0}";
  exitcode="1";
  modules=(new-object psobject -property @{ autoload=$false })
}

<#
-------------------------------------------------------------------
Specify defaults and auto-load modules from .\modules folder
-------------------------------------------------------------------
$psake.config = new-object psobject -property @{
  defaultbuildfilename="default.ps1";
  tasknameformat="Executing {0}";
  exitcode="1";
  modules=(new-object psobject -property @{ autoload=$true})
}

-------------------------------------------------------------------
Specify defaults and auto-load modules from .\my_modules folder
-------------------------------------------------------------------
$psake.config = new-object psobject -property @{
  defaultbuildfilename="default.ps1";
  tasknameformat="Executing {0}";
  exitcode="1";
  modules=(new-object psobject -property @{ autoload=$true; directory=".\my_modules" })
}

-------------------------------------------------------------------
Specify defaults and explicitly load module(s)
-------------------------------------------------------------------
$psake.config = new-object psobject -property @{
  defaultbuildfilename="default.ps1";
  tasknameformat="Executing {0}";
  exitcode="1";
  modules=(new-object psobject -property @{
    autoload=$false; 
    module=(new-object psobject -property @{path="c:\module1dir\module1.ps1"}), 
           (new-object psobject -property @{path="c:\module1dir\module2.ps1"})
  })
}
#>