<p>
Since *psake* is written in PowerShell, all variables follow the PowerShell scoping rules (PS> help about_scope).  All the variables declared in the "properties" function have the "script" level scope and any variables declared within a "task" function are local variables.  

This means you can reference the "properties" variables from any "task" function but all variables declared within "task" function are not accessible from other "task" functions in the build script. 

The following is an example build script that uses a property variable from 2 different task functions:
 </p>
<pre>
properties {
  $x = 1
}

task default -depends TaskA, TaskB

task TaskA {
  '$x = ' + $x
}

task TaskB {
 '$x = ' + $x
}
</pre>
<p>
The output from running the above build is:
</p>
<pre>
Executing task: TaskA
$x = 1
Executing task: TaskB
$x = 1

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
TaskA  00:00:00.0086706
TaskB  00:00:00.0056644
Total: 00:00:00.0801045
</pre>
<p>
Sometimes you may want/need to set a variable or update a property within a task and then refer to that variable/property from another task.

The following example build script shows how to do that using the "script" scope modifier
</p>
<pre>
properties {
  $x = 1
}

task default -depends TaskA, TaskB

task TaskA {
  $script:x = 100
  '$x = ' + $script:x
}

task TaskB {
 '$x = ' + $script:x
}
</pre>
<p>
The output from the above script:
</p>
<pre>
Executing task: TaskA
$x = 100
Executing task: TaskB
$x = 100

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
TaskA  00:00:00.0057736
TaskB  00:00:00.0054096
Total: 00:00:00.0820067
</pre>
<p>
The following example does not update a property, it sets a "script" level variable ("y") within one task and references it in another task.
</p>
<pre>
task default -depends TaskA, TaskB

task TaskA {
  $script:y = 100
  '$y = ' + $script:y
}

task TaskB {
 '$y = ' + $script:y
}
</pre>
<p>
The output from the above build script:
</p>
<pre>
Executing task: TaskA
$y = 100
Executing task: TaskB
$y = 100

Build Succeeded!

----------------------------------------------------------------------
Build Time Report
----------------------------------------------------------------------
Name   Duration
----   --------
TaskA  00:00:00.0047757
TaskB  00:00:00.0048073
Total: 00:00:00.1244049
</pre>

<p>In case you create a variable with script scope, the variable is kept inside the psake module. This means, that if you run Invoke-Psake again, the variable is available. That’s why variables with script scope should be used carefully. Consider them as global variables accessible for all scripts running in psake.</p>