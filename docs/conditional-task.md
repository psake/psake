You can conditionally run a task by using the "precondition" parameter of the "task" function.  The "precondition" parameter expects a scriptblock as its value and that scriptblock should return a $true or $false.

The following is an example build script that uses the "precondition" parameter of the task function:

```powershell
task default -depends A,B,C

task A {
  "TaskA"
}

task B -precondition { return $false } {
  "TaskB"
}

task C -precondition { return $true } {
  "TaskC"
}
```

The output from running the above build script looks like the following:

```
Executing task: A
TaskA
Precondition was false not executing B
Executing task: C
TaskC

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
A      00:00:00.0231283
B      0
C      00:00:00.0043444
Total: 00:00:00.1405840
```

Notice how task "B" was not executed and its run-time duration was 0 secs.
