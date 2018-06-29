You can pass parameters to your build script using the "parameters" parameter of the Invoke-psake function.  The following is an example:

```
 C:\PS>Invoke-psake .\parameters.ps1 -parameters @{"p1"="v1";"p2"="v2"}
```

The example above runs the build script called "parameters.ps1" and passes in parameters 'p1' and 'p2' with values 'v1' and 'v2'.  The parameter value for the "parameters" parameter (say that 10 times really fast!) is a PowerShell hashtable where the name and value of each parameter is specified. Note:  You don't need to use the "$" character when specifying the parameter names in the hashtable.

The "parameters.ps1" build script looks like this:

```powershell
properties {
  $my_property = $p1 + $p2
}

task default -depends TestParams

task TestParams { 
  Assert ($my_property -ne $null) '$my_property should not be null'  
}
```
