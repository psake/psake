$psake.config = new-object psobject -property @{
  defaultbuildfilename="default.ps1";
  tasknameformat="Executing {0}";
  exitcode="1";
  modules=(new-object psobject -property @{ autoload=$true; directory=".\modules" })
}

<#
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