---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Get-PSakeScriptTasks

## SYNOPSIS
Returns meta data about all the tasks defined in the provided psake script.

## SYNTAX

```
Get-PSakeScriptTasks [[-buildFile] <String>] [<CommonParameters>]
```

## DESCRIPTION
Returns meta data about all the tasks defined in the provided psake script.

## EXAMPLES

### EXAMPLE 1
```
Get-PSakeScriptTasks -buildFile '.\build.ps1'
```

DependsOn        Alias Name    Description
---------        ----- ----    -----------
{}                     Compile
{}                     Clean
{Test}                 Default
{Clean, Compile}       Test

Gets the psake tasks contained in the 'build.ps1' file.

## PARAMETERS

### -buildFile
The path to the psake build script to read the tasks from.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Invoke-psake]()

