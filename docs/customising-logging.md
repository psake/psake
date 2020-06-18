By default, psake writes messages to the pipeline, where they typically end up displayed in the console window or the logs of a CI tool. However, sometimes you may want to handle output differently. Perhaps to ensure the psake messages are displayed or logged in a way which is consistent with the logging of your build scripts.

The code which controls how various messages are output are now exposed in the psake config, and can be overriden in two ways.

# Overriding A Specific Message Type

Each message that psake outputs is assigned a type such as "warning", "debug" or "default". Each type has it's own outputHandler script block in the psake config, which takes a single $output parameter. So you can change how a particular type of message is output by overriding them in the psake-config.ps1 file like so :

```powershell
$config.outputHandlers.default = {Param([object]$output) Write-Output "$(Get-Date -format "yyyy-MM-dd HH:mm:ss"): $output"}
$config.outputHandlers.warning = {Param([object]$output) CustomFunction "$(Get-Date -format "yyyy-MM-dd HH:mm:ss"): $output"}
```

This example prefixes all default and warning messages with a date and timestamp, and the warning messages are sent to a custom function defined in the build file.

# Overriding The outputHandler

The process of routing various types of message to the output handlers is performed by an outputHandler script block in the psake config.

However, if the default behaviour of routing messages to handlers based on their type doesn't work for you, you can also override the outputHandler itself, like so :

```powershell
$config.outputHandler = {
    [CmdLetBinding()]
    Param (
        [Parameter(Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [object]$Output,
        [Parameter(Position=1,ValueFromPipelineByPropertyName=$true)]
        [string]$OutputType = "default"
    )

    Process {
        CustomFunction $Output $OutputType
    }
 };
```

This example routes all messages, regardless of $OutputType, to a custom function.
