properties {
    $z = $null
}

task default -depends TestWithAction, TestWithoutAction

task TestWithAction -requiredVariables z {}

task TestWithoutAction -requiredVariables z
