---
external help file: psake-help.xml
Module Name: psake
online version: 
schema: 2.0.0
---

# TaskTearDown

## SYNOPSIS
Adds a scriptblock to the build that will be executed after each task

## SYNTAX

```
TaskTearDown [-teardown] <ScriptBlock>
```

## DESCRIPTION
This function will accept a scriptblock that will be executed after each task in the build script.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
A sample build script is shown below:
```

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

TaskTearDown {
    "Running 'TaskTearDown' for task $context.Peek().currentTaskName"
}

The script above produces the following output:

Executing task, Clean...
Running 'TaskTearDown' for task Clean
Executing task, Compile...
Running 'TaskTearDown' for task Compile
Executing task, Test...
Running 'TaskTearDown' for task Test

Build Succeeded

## PARAMETERS

### -teardown
A scriptblock to execute

```yaml
Type: ScriptBlock
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

