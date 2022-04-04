---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Task

## SYNOPSIS
Defines a build task to be executed by psake

## SYNTAX

### Normal (Default)
```
Task [-Name] <String> [[-Action] <ScriptBlock>] [[-PreAction] <ScriptBlock>] [[-PostAction] <ScriptBlock>]
 [[-PreCondition] <ScriptBlock>] [[-PostCondition] <ScriptBlock>] [-ContinueOnError] [[-Depends] <String[]>]
 [[-RequiredVariables] <String[]>] [[-Description] <String>] [[-Alias] <String>] [<CommonParameters>]
```

### SharedTask
```
Task [-Name] <String> [[-Action] <ScriptBlock>] [[-PreAction] <ScriptBlock>] [[-PostAction] <ScriptBlock>]
 [[-PreCondition] <ScriptBlock>] [[-PostCondition] <ScriptBlock>] [-ContinueOnError] [[-Depends] <String[]>]
 [[-RequiredVariables] <String[]>] [[-Description] <String>] [[-Alias] <String>] [-FromModule] <String>
 [[-RequiredVersion] <String>] [[-MinimumVersion] <String>] [[-MaximumVersion] <String>]
 [[-LessThanVersion] <String>] [<CommonParameters>]
```

## DESCRIPTION
This function creates a 'task' object that will be used by the psake engine to execute a build task.
Note: There must be at least one task called 'default' in the build script

## EXAMPLES

### EXAMPLE 1
```
A sample build script is shown below:
```

Task default -Depends Test

Task Test -Depends Compile, Clean {
    "This is a test"
}

Task Compile -Depends Clean {
    "Compile"
}

Task Clean {
    "Clean"
}

The 'default' task is required and should not contain an 'Action' parameter.
It uses the 'Depends' parameter to specify that 'Test' is a dependency

The 'Test' task uses the 'Depends' parameter to specify that 'Compile' and 'Clean' are dependencies
The 'Compile' task depends on the 'Clean' task.

Note:
The 'Action' parameter is defaulted to the script block following the 'Clean' task.

An equivalent 'Test' task is shown below:

Task Test -Depends Compile, Clean -Action {
    $testMessage
}

The output for the above sample build script is shown below:

Executing task, Clean...
Clean
Executing task, Compile...
Compile
Executing task, Test...
This is a test

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name    Duration
----    --------
Clean   00:00:00.0065614
Compile 00:00:00.0133268
Test    00:00:00.0225964
Total:  00:00:00.0782496

## PARAMETERS

### -Name
The name of the task

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

### -Action
A scriptblock containing the statements to execute for the task.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreAction
A scriptblock to be executed before the 'Action' scriptblock.
Note: This parameter is ignored if the 'Action' scriptblock is not defined.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostAction
A scriptblock to be executed after the 'Action' scriptblock.
Note: This parameter is ignored if the 'Action' scriptblock is not defined.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreCondition
A scriptblock that is executed to determine if the task is executed or skipped.
This scriptblock should return $true or $false

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: {$true}
Accept pipeline input: False
Accept wildcard characters: False
```

### -PostCondition
A scriptblock that is executed to determine if the task completed its job correctly.
An exception is thrown if the scriptblock returns $false.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: {$true}
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContinueOnError
If this switch parameter is set then the task will not cause the build to fail when an exception is thrown by the task

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Depends
An array of task names that this task depends on.
These tasks will be executed before the current task is executed.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredVariables
An array of names of variables that must be set to run this task.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: @()
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A description of the task.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Alias
An alternate name for the task.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 11
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FromModule
Load in the task from the specified PowerShell module.

```yaml
Type: String
Parameter Sets: SharedTask
Aliases:

Required: True
Position: 12
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RequiredVersion
The specific version of a module to load the task from

```yaml
Type: String
Parameter Sets: SharedTask
Aliases: Version

Required: False
Position: 13
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumVersion
The minimum (inclusive) version of the PowerShell module to load in the task from.

```yaml
Type: String
Parameter Sets: SharedTask
Aliases:

Required: False
Position: 14
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaximumVersion
The maximum (inclusive) version of the PowerShell module to load in the task from.

```yaml
Type: String
Parameter Sets: SharedTask
Aliases:

Required: False
Position: 15
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LessThanVersion
The version of the PowerShell module to load in the task from that should not be met or exceeded.
eg -LessThanVersion 2.0.0 will reject anything 2.0.0 or higher, allowing any module in the 1.x.x series.

```yaml
Type: String
Parameter Sets: SharedTask
Aliases:

Required: False
Position: 16
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

[TaskSetup]()

[TaskTearDown]()

