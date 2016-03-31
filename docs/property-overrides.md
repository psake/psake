You can override a property in your build script using the "properties" parameter of the Invoke-psake function.  The following is an example:

```
C:\PS>Invoke-psake .\properties.ps1 -properties @{"x"="1";"y"="2"}
```

The example above runs the build script called "properties.ps1" and passes in parameters 'x' and 'y' with values '1' and '2'.  The parameter value for the "properties" parameter is a PowerShell hashtable where the name and value of each property is specified. Note:  You don't need to use the "$" character when specifying the property names in the hashtable.

The "properties.ps1" build script looks like this:

```powershell
properties {
	$x = $null
	$y = $null
	$z = $null
}

task default -depends TestProperties

task TestProperties {
  Assert ($x -ne $null) "x should not be null"
  Assert ($y -ne $null) "y should not be null"
  Assert ($z -eq $null) "z should be null"
}
```

The value of $x should be 1 and $y should be 2 by the time the "TestProperties" task is executed.  The value of $z was not over-ridden so it should still be $null.


To summarize the differences between passing parameters and properties to the Invoke-psake function:

* Parameters and "properties" can both be passed to the Invoke-psake function simultaneously
* Parameters are set before any "properties" blocks are run
* Properties are set after all "properties" blocks have run