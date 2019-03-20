TaskSetup {
    param($task)

    "Setting up: '$($task.Name)'"
    Assert ($task -ne $null) '$task should not be null'
    Assert (-not ([string]::IsNullOrWhiteSpace($task.Name))) '$task.Name should not be empty'
}

Task default -depends Compile, Test, Deploy

Task Compile {
    "Compiling"
}

Task Test -depends Compile {
    "Testing"
}

Task Deploy -depends Test {
    "Deploying"
}
