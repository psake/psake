properties {
    $x = 1
    $y = 2
}

task default -depends TestWithAction, TestWithoutAction

task TestWithAction -requiredVariables x, y {}

task TestWithoutAction -requiredVariables x, y
