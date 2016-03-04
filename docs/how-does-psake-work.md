<p>**psake** is a domain specific language to create builds using a dependency pattern just like Ant, NAnt, Rake or MSBuild.

You create a build script using PowerShell that consists of _Tasks_ which are simply function calls.  Each _Task_ function can define dependencies on other _Task_ functions.

In the example script below, Task _Compile_ depends on Tasks _Clean_ and _Init_, which means that before Task _Compile_ can execute, both tasks _Clean_ and _Init_ have to execute.  psake ensures that this is done.
</p>
<pre>
Task Compile -Depends Init,Clean {
   "compile"
}

Task Clean -Depends Init {
   "clean"
}

Task Init {
   "init"
}
</pre>
<p>
psake reads in your build script and executes the _Task_ functions that are defined within it and enforces the dependencies between tasks. The great thing about psake is that it is written in PowerShell and that means you have the power of .NET and all the features of PowerShell at your disposal within your build script.  Not to mention that you don't have to pay the *XML* bracket tax anymore.
</p>
