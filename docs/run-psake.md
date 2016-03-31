*psake* is a PowerShell module and is contained in a file named psake.psm1.

There are 2 ways to run psake:

1) Import the psake.psm1 module and call the Invoke-psake function
2) Call the psake.ps1 helper script

Following is the first option:

```powershell
Import-Module .\psake.psml
Invoke-psake .\default.ps1
```

Second option:

```powershell
# call the psake.ps1 file directly
.\psake.ps1 .\default.ps1
```

When you call the psake.ps1 script, it forwards the parameters on to the Invoke-psake function.

The benefit of option 1 is that you can get detailed help on the Invoke-psake function:

```powershell
Import-Module .\psake.psml
Get-Help Invoke-psake -full
```

You may also consider making a helper script for your builds so that you can configure any psake options  (-framework,  etc)

The following is an example helper script that configures psake to use the .NET 4.0 framework.

```powershell
Import-Module (join-path $PSScriptRoot psake.psm1) -force
Invoke-psake -framework '4.0'
```