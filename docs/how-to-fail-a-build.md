When you run a command-line program, you need to check the $lastexitcode PowerShell variable to determine if the command-line program failed.  If the $lastexitcode is non-zero that usually indicates a failure condition and you should throw a PowerShell exception so that your build script will fail appropriately.

Here is an example:

```powershell
task default -depends TaskA

task TaskA {
  #use cmd.exe and the DOS exit() function to simulate a failed command-line execution
  "Executing command-line program"
  cmd /c exit (1) 
}
```

The output from the above build script:

```
Executing task: TaskA
Executing command-line program

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
TaskA  00:00:00.1059589
Total: 00:00:00.2233691
```

The above build script will always succeed, even though we know the build should have failed

Here is an example that does fail correctly:

```powershell
task default -depends TaskA

task TaskA {
  #use cmd.exe and the DOS exit() function to simulate a failed command-line execution
  "Executing command-line program"
  cmd /c exit (1) 
  if ($lastexitcode -ne 0)
  {
    throw "Command-line program failed"
  }
}
```

A simpler option is to use the psake "exec" function to execute command-line programs

The following is an example:

```powershell
task default -depends TaskA
```
