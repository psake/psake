BuildSetup {
    $script:sequence += "executing build setup;"
}

Task default -depends Test-Results

Task Test-Results -depends Compile, Test, Deploy {
    [string]$expected = "executing build setup;Compiling;Testing;Deploying"
    if ($script:sequence -ne $expected) {
        throw "Expected sequence '$expected', but was actually '$script:sequence'"
    }
}

Task Compile {
    $script:sequence += "Compiling;"
}

Task Test -depends Compile {
    $script:sequence += "Testing;"
}

Task Deploy -depends Test {
    $script:sequence += "Deploying"
}
