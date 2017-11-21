---
external help file: psake-help.xml
Module Name: psake
online version: 
schema: 2.0.0
---

# FormatTaskName

## SYNOPSIS
This function allows you to change how psake renders the task name during a build.

## SYNTAX

```
FormatTaskName [-format] <Object>
```

## DESCRIPTION
This function takes either a string which represents a format string (formats using the -f format operator see "help about_operators") or it can accept a script block that has a single parameter that is the name of the task that will be executed.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
A sample build script that uses a format string is shown below:
```

Task default -depends TaskA, TaskB, TaskC

FormatTaskName "-------- {0} --------"

Task TaskA {
"TaskA is executing"
}

Task TaskB {
"TaskB is executing"
}

Task TaskC {
"TaskC is executing"

-----------
The script above produces the following output:

-------- TaskA --------
TaskA is executing
-------- TaskB --------
TaskB is executing
-------- TaskC --------
TaskC is executing

Build Succeeded!

### -------------------------- EXAMPLE 2 --------------------------
```
A sample build script that uses a ScriptBlock is shown below:
```

Task default -depends TaskA, TaskB, TaskC

FormatTaskName {
    param($taskName)
    write-host "Executing Task: $taskName" -foregroundcolor blue
}

Task TaskA {
"TaskA is executing"
}

Task TaskB {
"TaskB is executing"
}

Task TaskC {
"TaskC is executing"
}

-----------
The above example uses the scriptblock parameter to the FormatTaskName function to render each task name in the color blue.

Note: the $taskName parameter is arbitrary, it could be named anything.

## PARAMETERS

### -format
A format string or a scriptblock to execute

```yaml
Type: Object
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

[Framework]()

[Get-PSakeScriptTasks]()

[Include]()

[Invoke-psake]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

