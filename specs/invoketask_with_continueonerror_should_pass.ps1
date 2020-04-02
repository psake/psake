Task Default -Depends Test-DoesntFailBuildWhenTaskWritesToStandardError,Test-DoesntFailBuildWhenTaskThrowsException,Test-DoesntFailBuildWhenTaskIsSuccessful

Task Test-DoesntFailBuildWhenTaskWritesToStandardError -ContinueOnError {
    Write-Error "Task 1"
}

Task Test-DoesntFailBuildWhenTaskThrowsException -ContinueOnError {
    Throw "Task 2"
}

Task Test-DoesntFailBuildWhenTaskIsSuccessful -ContinueOnError {}