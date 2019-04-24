---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Properties

## SYNOPSIS
Define a scriptblock that contains assignments to variables that will be available to all tasks in the build script

## SYNTAX

```
Properties [-properties] <ScriptBlock> [<CommonParameters>]
```

## DESCRIPTION
A build script may declare a "Properies" function which allows you to define variables that will be available to all the "Task" functions in the build script.

## EXAMPLES

### EXAMPLE 1
```
A sample build script is shown below:
```

Properties {
    $build_dir = "c:\build"
    $connection_string = "datasource=localhost;initial catalog=northwind;integrated security=sspi"
}

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}

Note: You can have more than one "Properties" function defined in the build script.

## PARAMETERS

### -properties
The script block containing all the variable assignment statements

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

[Get-PSakeScriptTasks]()

[Include]()

[Invoke-psake]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

