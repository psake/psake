---
external help file: psake-help.xml
Module Name: psake
online version:
schema: 2.0.0
---

# Exec

## SYNOPSIS
Helper function for executing command-line programs.

## SYNTAX

```
Exec [-cmd] <ScriptBlock> [[-errorMessage] <String>] [[-maxRetries] <Int32>]
 [[-retryTriggerErrorPattern] <String>] [[-workingDirectory] <String>] [<CommonParameters>]
```

## DESCRIPTION
This is a helper function that runs a scriptblock and checks the PS variable $lastexitcode to see if an error occcured.
If an error is detected then an exception is thrown.
This function allows you to run command-line programs without having to explicitly check fthe $lastexitcode variable.

## EXAMPLES

### EXAMPLE 1
```
exec { svn info $repository_trunk } "Error executing SVN. Please verify SVN command-line client is installed"
```

This example calls the svn command-line client.

## PARAMETERS

### -cmd
The scriptblock to execute.
This scriptblock will typically contain the command-line invocation.

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

### -errorMessage
The error message to display if the external command returned a non-zero exit code.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: ($msgs.error_bad_command -f $cmd)
Accept pipeline input: False
Accept wildcard characters: False
```

### -maxRetries
The maximum number of times to retry the command before failing.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -retryTriggerErrorPattern
If the external command raises an exception, match the exception against this regex to determine if the command can be retried.
If a match is found, the command will be retried provided \[maxRetries\] has not been reached.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -workingDirectory
The working directory to set before running the external command.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[Assert]()

[FormatTaskName]()

[Framework]()

[Get-PSakeScriptTasks]()

[Include]()

[Invoke-psake]()

[Properties]()

[Task]()

[TaskSetup]()

[TaskTearDown]()

[Properties]()

