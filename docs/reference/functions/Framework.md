---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Framework

## SYNOPSIS
Sets the version of the .NET framework you want to use during build.

## SYNTAX

```
Framework [-framework] <String> [<CommonParameters>]
```

## DESCRIPTION
This function will accept a string containing version of the .NET framework to use during build.
Possible values: '1.0', '1.1', '2.0', '2.0x86', '2.0x64', '3.0', '3.0x86', '3.0x64', '3.5', '3.5x86', '3.5x64', '4.0', '4.0x86', '4.0x64', '4.5', '4.5x86', '4.5x64', '4.5.1', '4.5.1x86', '4.5.1x64'.
Default is '3.5*', where x86 or x64 will be detected based on the bitness of the PowerShell process.

## EXAMPLES

### EXAMPLE 1
```
Framework "4.0"
```

Task default -depends Compile

Task Compile -depends Clean {
    msbuild /version
}

-----------
The script above will output detailed version of msbuid v4

## PARAMETERS

### -framework
Version of the .NET framework to use during build.

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

[Get-PSakeScriptTasks]()

[Include]()

[Invoke-psake]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

