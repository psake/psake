Properties {
    [string]$testProperty = "Test123"
}

BuildTearDown {
    [string]$expected = "Test123"
    if ($testProperty -ne $expected) {
        throw "Expected '$expected', but was actually '$testProperty'"
    }
}

Task default -depends Compile,Test,Deploy

Task Compile {
    "Compiling"
}

Task Test -depends Compile {
    "Testing"
}

Task Deploy -depends Test {
    "Deploying"
}
