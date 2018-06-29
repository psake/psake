---
external help file: psake-help.xml
Module Name: psake
online version: 
schema: 2.0.0
---

# Invoke-psake

## SYNOPSIS
Runs a psake build script.

## SYNTAX

```
Invoke-psake [[-buildFile] <String>] [[-taskList] <String[]>] [[-framework] <String>] [-docs]
 [[-parameters] <Hashtable>] [[-properties] <Hashtable>] [[-initialization] <ScriptBlock>] [-nologo]
 [-detailedDocs] [-notr]
```

## DESCRIPTION
This function runs a psake build script

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Invoke-psake
```

Runs the 'default' task in the '.build.ps1' build script

### -------------------------- EXAMPLE 2 --------------------------
```
Invoke-psake '.\build.ps1' Tests,Package
```

Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script

### -------------------------- EXAMPLE 3 --------------------------
```
Invoke-psake Tests
```

This example will run the 'Tests' tasks in the 'psakefile.ps1' build script.
The 'psakefile.ps1' is assumed to be in the current directory.

### -------------------------- EXAMPLE 4 --------------------------
```
Invoke-psake 'Tests, Package'
```

This example will run the 'Tests' and 'Package' tasks in the 'psakefile.ps1' build script.
The 'psakefile.ps1' is assumed to be in the current directory.

### -------------------------- EXAMPLE 5 --------------------------
```
Invoke-psake .\build.ps1 -docs
```

Prints a report of all the tasks and their dependencies and descriptions and then exits

### -------------------------- EXAMPLE 6 --------------------------
```
Invoke-psake .\parameters.ps1 -parameters @{"p1"="v1";"p2"="v2"}
```

Runs the build script called 'parameters.ps1' and passes in parameters 'p1' and 'p2' with values 'v1' and 'v2'

Here's the .\parameters.ps1 build script:

properties {
    $my_property = $p1 + $p2
}

task default -depends TestParams

task TestParams {
    Assert ($my_property -ne $null) '$my_property should not be null'
}

Notice how you can refer to the parameters that were passed into the script from within the "properties" function.
The value of the $p1 variable should be the string "v1" and the value of the $p2 variable should be "v2".

### -------------------------- EXAMPLE 7 --------------------------
```
Invoke-psake .\properties.ps1 -properties @{"x"="1";"y"="2"}
```

Runs the build script called 'properties.ps1' and passes in parameters 'x' and 'y' with values '1' and '2'

This feature allows you to override existing properties in your build script.

Here's the .\properties.ps1 build script:

properties {
    $x = $null
    $y = $null
    $z = $null
}

task default -depends TestProperties

task TestProperties {
    Assert ($x -ne $null) "x should not be null"
    Assert ($y -ne $null) "y should not be null"
    Assert ($z -eq $null) "z should be null"
}

## PARAMETERS

### -buildFile
The path to the psake build script to execute

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -taskList
A comma-separated list of task names to execute

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: 

Required: False
Position: 2
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -framework
The version of the .NET framework you want to use during build.
You can append x86 or x64 to force a specific framework.
If not specified, x86 or x64 will be detected based on the bitness of the PowerShell process.
Possible values: '1.0', '1.1', '2.0', '2.0x86', '2.0x64', '3.0', '3.0x86', '3.0x64', '3.5', '3.5x86', '3.5x64', '4.0', '4.0x86', '4.0x64', '4.5', '4.5x86', '4.5x64', '4.5.1', '4.5.1x86', '4.5.1x64'

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -docs
Prints a list of tasks and their descriptions

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -parameters
A hashtable containing parameters to be passed into the current build script.
These parameters will be processed before the 'Properties' function of the script is processed.
This means you can access parameters from within the 'Properties' function!

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: 

Required: False
Position: 4
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -properties
A hashtable containing properties to be passed into the current build script.
These properties will override matching properties that are found in the 'Properties' function of the script.

```yaml
Type: Hashtable
Parameter Sets: (All)
Aliases: 

Required: False
Position: 5
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -initialization
Parameter description

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases: init

Required: False
Position: 6
Default value: {}
Accept pipeline input: False
Accept wildcard characters: False
```

### -nologo
Do not display the startup banner and copyright message.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -detailedDocs
Prints a more descriptive list of tasks and their descriptions.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -notr
Do not display the time report.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: 

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES
---- Exceptions ----

If there is an exception thrown during the running of a build script psake will set the '$psake.build_success' variable to $false.
To detect failue outside PowerShell (for example by build server), finish PowerShell process with non-zero exit code when '$psake.build_success' is $false.
Calling psake from 'cmd.exe' with 'psake.cmd' will give you that behaviour.

---- $psake variable ----

When the psake module is loaded a variable called $psake is created which is a hashtable
containing some variables:

$psake.version                      # contains the current version of psake
$psake.context                      # holds onto the current state of all variables
$psake.run_by_psake_build_tester    # indicates that build is being run by psake-BuildTester
$psake.config_default               # contains default configuration
                                    # can be overriden in psake-config.ps1 in directory with psake.psm1 or in directory with current build script
$psake.build_success                # indicates that the current build was successful
$psake.build_script_file            # contains a System.IO.FileInfo for the current build script
$psake.build_script_dir             # contains the fully qualified path to the current build script

You should see the following when you display the contents of the $psake variable right after importing psake

PS projects:\psake\\\> Import-Module .\psake.psm1
PS projects:\psake\\\> $psake

Name                           Value
----                           -----
run_by_psake_build_tester      False
version                        4.2
build_success                  False
build_script_file
build_script_dir
config_default                 @{framework=3.5; ...
context                        {}

After a build is executed the following $psake values are updated: build_script_file, build_script_dir, build_success

PS projects:\psake\\\> Invoke-psake .\examples\psakefile.ps1
Executing task: Clean
Executed Clean!
Executing task: Compile
Executed Compile!
Executing task: Test
Executed Test!

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0798486
Compile 00:00:00.0869948
Test    00:00:00.0958225
Total:  00:00:00.2712414

PS projects:\psake\\\> $psake

Name                           Value
----                           -----
build_script_file              YOUR_PATH\examples\psakefile.ps1
run_by_psake_build_tester      False
build_script_dir               YOUR_PATH\examples
context                        {}
version                        4.2
build_success                  True
config_default                 @{framework=3.5; ...

## RELATED LINKS

[Assert]()

[Exec]()

[FormatTaskName]()

[Framework]()

[Get-PSakeScriptTasks]()

[Include]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

[Properties]()

