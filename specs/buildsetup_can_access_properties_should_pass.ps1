Properties {
    [string]$testProperty = "Test123"
}

BuildSetup {
    [string]$expected = "Test123"
    if ($testProperty -ne $expected) {
        throw "Expected sequence '$expected', but was actually '$script:sequence'"
    }
}

Task default -depends Compile, Test, Deploy

Task Compile {
    "Compiling;"
}

Task Test -depends Compile {
    "Testing;"
}

Task Deploy -depends Test {
    "Deploying"
}
