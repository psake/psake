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
Invoke-Task [-taskName] <String>
```

## DESCRIPTION
This is a function that will allow you to invoke a Task from within another Task in the current build script.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
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

