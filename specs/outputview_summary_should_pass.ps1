Task default -depends Compile, Test

Task Compile {
    "Compiling"
}

Task Test -depends Compile {
    "Testing"
}
