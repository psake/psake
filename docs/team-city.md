###PowerShell runner or Command Line runner

TeamCity 6.5 has a bundled PowerShell runner, which can be used to run psake builds.  For older versions of TeamCity, the [PowerShell runner plug-in](http://confluence.jetbrains.net/display/TW/PowerShell) will do the job; you can download the plug-in's binaries [here](http://teamcity.jetbrains.net/repository/download/bt268/50151:id/teamcity-powershell.zip). See [Installing Additional Plugins](http://confluence.jetbrains.net/display/TCD6/Installing+Additional+Plugins) for general help on installing plug-ins for TeamCity.

Alternatively you can just run PowerShell.exe from Command Line Runner and then run psake. See example in [psake.cmd](https://github.com/psake/psake/blob/master/psake.cmd).

###Setup of PowerShell runner

Add a new build step and select **PowerShell** runner.

* Set your run mode (x86 or x64)
* Set your working directory (typically the directory where your build scripts are located)
* Select *Source code* mode in Script input
* Insert into Script Source

```
Import-Module 'PATH_TO_PSAKE_ROOT_FOLDER\psake.psm1'
Invoke-psake .\PSAKE_BUILD_FILENAME.ps1 RunTests 
```

* For 4.0.0: Make sure you have added **<code>$psake.use_exit_on_error = $true</code>** somewhere before the Invoke-psake call (e.g., amend the <code>psake.ps1</code> file)
* For 4.0.1 unofficial release on NuGet no additional steps are required
* For current development version append to `& .\psake.ps1` also `if ($psake.build_success -eq $false) { exit 1 } else { exit 0 }` to notify TeamCity about build failure

Now you are ready.

###Parameters

If you need parameterize your build script, you can use the predefined [TeamCity parameters and variables](http://confluence.jetbrains.net/display/TCD6/Defining+and+Using+Build+Parameters+in+Build+Configuration). Pass in the parameters as a hash table using the following syntax:

```
& .\psake.ps1 -parameters @{build_number=%build.number%}
```

You can pass multiple parameters by separating them with semicolons:

```
& .\psake.ps1 -parameters @{build_number=%build.number%; personal_build=%build.is.personal%}
```

If you are using PowerShell v3.0 or greater, you can get all of the TeamCity parameters into a hash with the following code in your .ps1 file:
```
$TCParams = ConvertFrom-StringData (Get-Content $env:TEAMCITY_BUILD_PROPERTIES_FILE -Raw);
```

After this code executes, you can access any TeamCity parameter as <code>$TCParams['parameter.name']</code> e.g. <code>$TCParams['build.number']</code>
