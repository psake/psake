Task 'Build' @{
    DependOn = 'Clean'
    Action   = { "This should fail because DependOn is not a valid key (should be DependsOn)" }
}

Task 'Default' @{ DependsOn = 'Build' }
