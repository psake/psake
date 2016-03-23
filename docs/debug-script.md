You can debug your psake build script in a couple of ways:
# Using *Set-PSBreakpoint*, *Get-PSBreakpoint* and *Remove-PSBreakpoint*
# Use the *PowerShell Integrated Scripting Environment (ISE)*

With *Set-PSBreakpoint* you need to know what line number you want to set a breakpoint on, but the syntax is pretty simple:

```powershell
Set-PSBreakpoint [-Script] <string[]> [-Line] <Int32[]> [[-Column] <int>] [-Action <scriptblock>] [<CommonParameters>]
ex.
Set-PSBreakPoint -script default.ps1 -line 25
```

Once the breakpoint is set then you call the invoke-psake function on your script as normal and you should get a prompt from the command window:

```
Entering debug mode. Use h or ? for help.

Hit Line breakpoint on 'C:\Users\Daddy\Documents\Projects\psake\default.ps1:9'

default.ps1:9     "TaskA is executing"
[DBG]: PS C:\Users\Daddy\Documents\Projects\psake>>>
```

If you type "h" you will get the following options that will allow you to debug your script:

```
 s, stepInto         Single step (step into functions, scripts, etc.)
 v, stepOver         Step to next statement (step over functions, scripts, etc.)
 o, stepOut          Step out of the current function, script, etc.

 c, continue         Continue execution
 q, quit             Stop execution and exit the debugger

 k, Get-PSCallStack  Display call stack

 l, list             List source code for the current script.
                     Use "list" to start from the current line, "list <m>"
                     to start from line <m>, and "list <m> <n>" to list <n>
                     lines starting from line <m>

 <enter>             Repeat last command if it was stepInto, stepOver or list

 ?, h                Displays this help message
```

While debugging you are able to inspect the values of your variables by just typing them at the prompt and hitting the [Enter] key

Once you are done debugging you can call *Remove-PSBreakpoint* to remove the breakpoints you've added,  you can use *Get-PSBreakpoint* to get a list of all the current breakpoints in the current session.  

With the *PowerShell Integrated Scripting Environment* all you need to do is to load your build script and click on the left margin to set a breakpoint, then run the invoke-psake function from the command window that is within the ISE (its in the bottom pane of the ISE).  Then you can use the functions keys to debug your build script (F10, F11, etc.. they are under the "Debug" menu).
