task default -depends Test

task Test -depends Compile, Clean {}

task Compile -depends Clean {
    "Compile"
}

task Clean {
    "Clean"
}

taskTearDown {
    param($task)

    Assert ($task -ne $null) '$task should not be null'
    Assert (-not ([string]::IsNullOrWhiteSpace($task.Name))) '$task.Name should not be null'
    "'$($task.Name)' Tear Down"
}
