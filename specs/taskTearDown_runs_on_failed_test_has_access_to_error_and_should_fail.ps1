task default -depends Test

task Test -depends Compile, Clean {
    Assert $false "This fails."
}

task Compile -depends Clean {
    "Compile"
}

task Clean {
    "Clean"
}

taskTearDown {
    param($task)

    Assert ($task.Name -eq $psake.context.Peek().currentTaskName) 'TaskName should match'
    if ($task.Success) {
        "'$($task.Name)' Tear Down: task passed!"
    } else {
        "'$($task.Name)' Tear Down: task failed with '$($task.ErrorMessage)'"
        "-------------------"
        "- ErrorMessage: '$($task.ErrorMessage)'"
        "- ErrorDetail: $($task.ErrorDetail)"
        "- ErrorFormatted: $($task.ErrorFormatted)"
        "-------------------"
    }
}
