task default -depends CheckMessagesRoutedToDefault

task CheckMessagesRoutedToDefault {
    [string[]]$output = Invoke-psake ".\outputhandler_routes_unknown_message_type_to_default_handler\outputhandler_routes_unknown_message_type_to_default_handler.ps1" 3>&1
    [string[]]$outputType = @("heading","default","debug","warning","error","success","other")

    $outputType | ForEach-Object {Assert ($output -contains "default : $_") "Message with type '$_' was not re-routed to the default outputHandler"}
}
