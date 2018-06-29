The *Task* function has a switch parameter called "ContinueOnError" that you can set if you want the build to continue running if that particular task throws an exception.

Here's an example script that uses the "ContinueOnError" switch:

```powershell
Task default -Depends TaskA

Task TaskA -Depends TaskB {
	"Task - A"
}

Task TaskB -Depends TaskC -ContinueOnError {
	"Task - B"
	throw "I failed on purpose!"
}

Task TaskC {
	"Task - C"
}
```

When you run the above build script, you should get this output:

```
Executing task: TaskC
Task - C
Executing task: TaskB
Task - B
-----------------------------------------------------------------
Error in Task [TaskB] I failed on purpose!
-----------------------------------------------------------------
Executing task: TaskA
Task - A

Build Succeeded!

-----------------------------------------------------------------
Build Time Report
-----------------------------------------------------------------
Name   Duration
----   --------
TaskC  00:00:00.0053110
TaskB  00:00:00.0256725
TaskA  00:00:00.0350228
Total: 00:00:00.1032888
```

When psake processes a task that throws an exception (TaskB in this example) and the "ContinueOnError" is set, then psake displays a message to the console indicating that the task had an error and continues processing the rest of the build script.

Note: The dependent tasks of the task that threw the exception still execute