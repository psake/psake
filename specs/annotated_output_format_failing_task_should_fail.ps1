task default -depends FailingTask

task FailingTask {
    throw "Test error from annotated output format spec"
}
