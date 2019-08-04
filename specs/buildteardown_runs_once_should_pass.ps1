BuildTearDown {
    $script:buildTearDown_Sequence += "executing build teardown"
    [string]$expected = "Compiling;Testing;Deploying;executing build teardown"
    if ($script:buildTearDown_Sequence -ne $expected) {
        throw "Expected sequence '$expected', but was actually '$script:buildTearDown_Sequence'"
    }
}

Task default -depends Test-Results

Task Test-Results -depends Compile, Test, Deploy {

}

Task Compile {
    $script:buildTearDown_Sequence += "Compiling;"
}

Task Test -depends Compile {
    $script:buildTearDown_Sequence += "Testing;"
}

Task Deploy -depends Test {
    $script:buildTearDown_Sequence += "Deploying;"
}
