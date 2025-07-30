Task default -depends CheckMessagesRoutedCorrectly

Task CheckMessagesRoutedCorrectly {
    [string[]]$output = Invoke-psake ".\outputhandler_routes_messages_to_specified_handler_type\outputhandler_routes_messages_to_specified_handler_type.ps1"
    [string[]]$outputType = @(
        'Heading',
        'Default',
        'Debug',
        'Warning',
        'Error',
        'Success'
    )

    $outputType | ForEach-Object { Assert ($output -contains "$_ : $_") "Message with type '$_' was not routed to the relevant outputHandler" }
}
