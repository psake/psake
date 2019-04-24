---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Invoke-Task

## SYNOPSIS
Executes another task in the current build script.

## SYNTAX

```
Invoke-Task [-taskName] <String> [<CommonParameters>]
```

## DESCRIPTION
This is a function that will allow you to invoke a Task from within another Task in the current build script.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Task "Compile"
```

This example calls the "Compile" task.

## PARAMETERS

### -taskName
The name of the task to execute.

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Assert]()

[Exec]()

[FormatTaskName]()

[Framework]()

[Get-PSakeScriptTasks]()

[Include]()

[Invoke-psake]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

