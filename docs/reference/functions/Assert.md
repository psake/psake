---
external help file: psake-help.xml
Module Name: psake
online version: 
schema: 2.0.0
---

# Assert

## SYNOPSIS
Helper function for "Design by Contract" assertion checking.

## SYNTAX

```
Assert [-conditionToCheck] <Object> [-failureMessage] <String>
```

## DESCRIPTION
This is a helper function that makes the code less noisy by eliminating many of the "if" statements that are normally required to verify assumptions in the code.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Assert $false "This always throws an exception"
```

Example of an assertion that will always fail.

### -------------------------- EXAMPLE 2 --------------------------
```
Assert ( ($i % 2) -eq 0 ) "$i is not an even number"
```

This exmaple may throw an exception if $i is not an even number

Note:
It might be necessary to wrap the condition with paranthesis to force PS to evaluate the condition
so that a boolean value is calculated and passed into the 'conditionToCheck' parameter.

Example:
    Assert 1 -eq 2 "1 doesn't equal 2"

PS will pass 1 into the condtionToCheck variable and PS will look for a parameter called "eq" and
throw an exception with the following message "A parameter cannot be found that matches parameter name 'eq'"

The solution is to wrap the condition in () so that PS will evaluate it first.

Assert (1 -eq 2) "1 doesn't equal 2"

## PARAMETERS

### -conditionToCheck
The boolean condition to evaluate

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

### -failureMessage
The error message used for the exception if the conditionToCheck parameter is false

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

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

