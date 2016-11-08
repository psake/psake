[Hudson](http://hudson-ci.org/) is a popular continuous integration server, it can be used to run pretty much any kind of build.  To have Hudson run your psake build script you just need to create a Hudson job that will launch PowerShell with a parameter that is a PowerShell helper script that will in turn load the psake.psm1 module and then call the Invoke-psake function.  You can use the psake.ps1 helper script but you will need to modify it so that the $psake.use_exit_on_error is set to $true.

Here's the modified psake.ps1 file

```powershell
# Helper script for those who want to run psake without importing the module.
# Example:
# .\psake.ps1 "psakefile.ps1" "BuildHelloWord" "4.0" 

# Must match parameter definitions for psake.psm1/invoke-psake 
# otherwise named parameter binding fails

param(
  [Parameter(Position=0,Mandatory=0)]
  [string]$buildFile = 'psakefile.ps1',
  [Parameter(Position=1,Mandatory=0)]
  [string[]]$taskList = @(),
  [Parameter(Position=2,Mandatory=0)]
  [string]$framework = '3.5',
  [Parameter(Position=3,Mandatory=0)]
  [switch]$docs = $false,
  [Parameter(Position=4,Mandatory=0)]
  [System.Collections.Hashtable]$parameters = @{},
  [Parameter(Position=5, Mandatory=0)]
  [System.Collections.Hashtable]$properties = @{}
)

try {
  $scriptPath = Split-Path $script:MyInvocation.MyCommand.Path
  import-module (join-path $scriptPath psake.psm1)
  $psake.use_exit_on_error = $true
  invoke-psake $buildFile $taskList $framework $docs $parameters $properties
} finally {
  remove-module psake -ea 'SilentlyContinue'
}
```

Configure Hudson to call PowerShell passing in the helper script as a parameter:

```
powershell.exe "& 'psake.ps1 psakefile.ps1'"
```

I've written a blog [post](http://matosjorge.spaces.live.com/blog/cns!2E0DA1D30B684DA8!710.entry) that shows how to do this without using a helper script.  It uses a Hudson PowerShell plug-in that allows you to enter PowerShell commands directly into the Hudson job configuration.
