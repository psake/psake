Task default -depends CheckMessagesRoutedToDefault

Task CheckMessagesRoutedToDefault {
    [string[]]$output = Invoke-psake ".\outputhandler_routes_unknown_message_type_to_default_handler\outputhandler_routes_unknown_message_type_to_default_handler.ps1" 3>&1
    [string[]]$outputType = @(
        'Heading',
        'Default',
        'Debug',
        'Warning',
        'Error',
        'Success'
    )

    $outputType | ForEach-Object { Assert ($output -contains "Default : $_") "Message with type '$_' was not re-routed to the default outputHandler" }
}
