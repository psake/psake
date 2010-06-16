## Welcome to psake on GitHub.

*psake* is a build automation tool written in PowerShell. It avoids the angle-bracket tax associated with executable XML by leveraging the PowerShell syntax in your build scripts. 

## How to get started:

**Step 1:** Download and extract the project

**Step 2:** CD into the directory where you extracted the project (where the psake.psm1 file is)

> Import-Module .\psake.psm1
>
> Get-Help Invoke-psake -Full   #this will show you help and examples of how to use psake
	
**Step 3:** Run some examples

> CD .\examples
>
> Invoke-psake    					# This will execute the "default" task in the "default.ps1"
>
> Invoke-psake .\default.ps1 Clean  # will execute the single task in the default.ps1 script

If you encounter the following error "Import-Module : ...psake.psm1 cannot be loaded because the execution of scripts is disabled on this system. Please see "get-help about_signing" for more details.
Run PowerShell as administrator
> Set-ExecutionPolicy RemoteSigned

## How To Contribute, Collaborate, Communicate

If you'd like to get involved with psake, we have discussion groups over at google: **[psake-dev](http://groups.google.com/group/psake-dev)** **[psake-users](http://groups.google.com/group/psake-users)**

Anyone can fork the main repository and submit patches, as well. And lastly, the [wiki](http://wiki.github.com/JamesKovacs/psake/) and [issues list](http://github.com/JamesKovacs/psake/issues) are also open for additions, edits, and discussion.

## Contributors

Many thanks for contributions to psake are due (in alphabetical order):

* candland
* ElegantCode
* lanwin
* smbecker
* stej
