The latest version of **psake** no longer provides a way to log errors to a file.  Most builds are executed by a continuous integration server which already logs all console output so it's redundant to provide that same functionality in psake. If an error does occur detailed error information is emitted to the console so that it will get saved by whatever CI server is running psake.

Here is an example of an error from a psake build script:

```
----------------------------------------------------------------------
4/25/2010 2:36:21 PM: An Error Occurred. See Error Details Below: 
----------------------------------------------------------------------
ErrorRecord
PSMessageDetails      : 
Exception             : System.Management.Automation.RuntimeException: This is a test
TargetObject          : This is a test
CategoryInfo          : OperationStopped: (This is a test:String) [], RuntimeException
FullyQualifiedErrorId : This is a test
ErrorDetails          : 
InvocationInfo        : System.Management.Automation.InvocationInfo
PipelineIterationInfo : {}

ErrorRecord.InvocationInfo
MyCommand        : 
BoundParameters  : {}
UnboundArguments : {}
ScriptLineNumber : 4
OffsetInLine     : 7
HistoryId        : 34
ScriptName       : C:\Users\Daddy\Documents\Projects\helloworld\Build\LogError.ps1
Line             :     throw "This is a test"
PositionMessage  : 
                   At C:\Users\Daddy\Documents\Projects\helloworld\Build\LogError.ps1:4 char:7
                   +     throw <<<<  "This is a test"
InvocationName   : throw
PipelineLength   : 0
PipelinePosition : 0
ExpectingInput   : False
CommandOrigin    : Internal

Exception
0000000000000000000000000000000000000000000000000000000000000000000000
ErrorRecord                 : This is a test
StackTrace                  : 
WasThrownFromThrowStatement : True
Message                     : This is a test
Data                        : {}
InnerException              : 
TargetSite                  : 
HelpLink                    : 
Source                      : 

----------------------------------------------------------------------
Script Variables
----------------------------------------------------------------------

Name                           Value                                                                                                         
----                           -----                                                                                                         
_                                                                                                                                            
args                           {}                                                                                                            
context                        {System.Collections.Hashtable}                                                                                
Error                          {}                                                                                                            
false                          False                                                                                                         
input                          System.Collections.ArrayList+ArrayListEnumeratorSimple                                                        
MaximumAliasCount              4096                                                                                                          
MaximumDriveCount              4096                                                                                                          
MaximumErrorCount              256                                                                                                           
MaximumFunctionCount           4096                                                                                                          
MaximumVariableCount           4096                                                                                                          
MyInvocation                   System.Management.Automation.InvocationInfo                                                                   
null                                                                                                                                         
psake                          {build_script_file, version, default_build_file_name, use_exit_on_error...}                                   
this                                                                                                                                         
true                           True              
```
