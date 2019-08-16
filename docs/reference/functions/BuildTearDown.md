---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# BuildTearDown

## SYNOPSIS
Adds a scriptblock that will be executed once at the end of the build

## SYNTAX

```
BuildTearDown [-setup] <ScriptBlock> [<CommonParameters>]
```

## DESCRIPTION
This function will accept a scriptblock that will be executed once at the end of the build, regardless of success or failure

## EXAMPLES

### EXAMPLE 1
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
BuildTearDown {
    "Running 'BuildTearDown'"
}
The script above produces the following output:
Executing task, Clean...
Executing task, Compile...
Executing task, Test...
Running 'BuildTearDown'
Build Succeeded

### EXAMPLE 2
```
A failing build script is shown below:
```

Task default -depends Test
Task Test -depends Compile, Clean {
    throw "forced error"
}
Task Compile -depends Clean {
}
Task Clean {
}
BuildTearDown {
    "Running 'BuildTearDown'"
}
The script above produces the following output:
Executing task, Clean...
Executing task, Compile...
Executing task, Test...
Running 'BuildTearDown'
forced error
At line:x char:x ...

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

[Invoke-psake]()

[Properties]()

[Task]()

[BuildSetup]()

[TaskSetup]()

[TaskTearDown]()

