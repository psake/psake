---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Include

## SYNOPSIS
Include the functions or code of another powershell script file into the current build script's scope

## SYNTAX

```
Include [-fileNamePathToInclude] <String> [<CommonParameters>]
```

## DESCRIPTION
A build script may declare an "includes" function which allows you to define a file containing powershell code to be included
and added to the scope of the currently running build script.
Code from such file will be executed after code from build script.

## EXAMPLES

### EXAMPLE 1
```
A sample build script is shown below:
```

Include ".\build_utils.ps1"

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

-----------
The script above includes all the functions and variables defined in the ".\build_utils.ps1" script into the current build script's scope

Note: You can have more than 1 "Include" function defined in the build script.

## PARAMETERS

### -fileNamePathToInclude
A string containing the path and name of the powershell file to include

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Assert]()

[Exec]()

[FormatTaskName]()

[Framework]()

[Get-PSakeScriptTasks]()

[Invoke-psake]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

