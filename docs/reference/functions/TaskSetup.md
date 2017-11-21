---
external help file: psake-help.xml
Module Name: psake
online version: 
schema: 2.0.0
---

# TaskSetup

## SYNOPSIS
Adds a scriptblock that will be executed before each task

## SYNTAX

```
TaskSetup [-setup] <ScriptBlock>
```

## DESCRIPTION
This function will accept a scriptblock that will be executed before each task in the build script.

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

TaskSetup {
    "Running 'TaskSetup' for task $context.Peek().currentTaskName"
}

The script above produces the following output:

Running 'TaskSetup' for task Clean
Executing task, Clean...
Running 'TaskSetup' for task Compile
Executing task, Compile...
Running 'TaskSetup' for task Test
Executing task, Test...

Build Succeeded

## PARAMETERS

### -setup
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

[TaskTearDown]()

