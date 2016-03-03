<p>
Use the psake *FormatTaskName* function. This function takes either a string which represents a format string (formats using the -f format operator see "help about_operators") or it can accept a script block that has a single parameter that is the name of the task that will be executed.

Here is an example using the format string parameter of the *FormatTaskName* parameter:
</p>
<pre>
Task default -depends TaskA, TaskB, TaskC

FormatTaskName "-------- {0} --------"

Task TaskA {
  "TaskA is executing"  
}

Task TaskB {
  "TaskB is executing"  
}

Task TaskC {
  "TaskC is executing"  
}
</pre>
<p>
The output looks like the following:
</p>
<pre>
-------- TaskA --------
TaskA is executing
-------- TaskB --------
TaskB is executing
-------- TaskC --------
TaskC is executing

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
TaskA  00:00:00.0058887
TaskB  00:00:00.0057582
TaskC  00:00:00.0043072
Total: 00:00:00.1919297
</pre>
<p>
The following example uses the scriptblock parameter of the *FormatTaskName* function:
</p>
<pre>
Task default -depends TaskA, TaskB, TaskC

FormatTaskName {
   param($taskName)
   write-host "Executing Task: $taskName" -foregroundcolor blue
}

Task TaskA {
  "TaskA is executing"  
}

Task TaskB {
  "TaskB is executing"  
}

Task TaskC {
  "TaskC is executing"  
}
</pre>
<p>
The preceding example uses the scriptblock parameter to the FormatTaskName function to render each task name in the color blue.

Note: the $taskName parameter is arbitrary it could be named anything
</p>