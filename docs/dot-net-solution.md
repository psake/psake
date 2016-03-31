Here's an example of a basic script you can write to build a Visual Studio.Net solution:

```powershell
Task Default -depends Build

Task Build {
   Exec { msbuild "helloworld.sln" }
}
```

Builds tend to be more complex than what's shown in the example above.  Most builds will need to know what the current directory is relative to where the build script was executed or where to look for code, where to deploy build artifacts or svn settings, etc...

If you haven't guessed already, I'm referring to build properties.

Here's a script that uses properties:

```powershell
#This build assumes the following directory structure
#
#  \Build          - This is where the project build code lives
#  \BuildArtifacts - This folder is created if it is missing and contains output of the build
#  \Code           - This folder contains the source code or solutions you want to build
#
Properties {
	$build_dir = Split-Path $psake.build_script_file
	$build_artifacts_dir = "$build_dir\..\BuildArtifacts\"
	$code_dir = "$build_dir\..\Code"
}

FormatTaskName (("-"*25) + "[{0}]" + ("-"*25))

Task Default -Depends BuildHelloWorld

Task BuildHelloWorld -Depends Clean, Build

Task Build -Depends Clean {
	Write-Host "Building helloworld.sln" -ForegroundColor Green
	Exec { msbuild "$code_dir\helloworld\helloworld.sln" /t:Build /p:Configuration=Release /v:quiet /p:OutDir=$build_artifacts_dir }
}

Task Clean {
	Write-Host "Creating BuildArtifacts directory" -ForegroundColor Green
	if (Test-Path $build_artifacts_dir)
	{
		rd $build_artifacts_dir -rec -force | out-null
	}

	mkdir $build_artifacts_dir | out-null

	Write-Host "Cleaning helloworld.sln" -ForegroundColor Green
	Exec { msbuild "$code_dir\helloworld\helloworld.sln" /t:Clean /p:Configuration=Release /v:quiet }
}
```

Here's a helper script "run-build.ps1" that I use to load the psake module and execute the build:

```powershell
$scriptPath = Split-Path $MyInvocation.InvocationName
Import-Module (join-path $scriptPath psake.psm1)
invoke-psake -framework '4.0'
```

I run the build in powershell by just running the script:

```
PS > .\run-build.ps1
```

The output from running the above build:

```
-------------------------[Clean]-------------------------
Creating BuildArtifacts directory
Cleaning helloworld.sln
Microsoft (R) Build Engine Version 4.0.30319.1
[Microsoft .NET Framework, Version 4.0.30319.1]
Copyright (C) Microsoft Corporation 2007. All rights reserved.

-------------------------[Build]-------------------------
Building helloworld.sln
Microsoft (R) Build Engine Version 4.0.30319.1
[Microsoft .NET Framework, Version 4.0.30319.1]
Copyright (C) Microsoft Corporation 2007. All rights reserved.


Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name            Duration
----            --------
Clean           00:00:09.4624557
Build           00:00:12.2191711
BuildHelloWorld 00:00:21.6931903
Total:          00:00:21.8308190
```