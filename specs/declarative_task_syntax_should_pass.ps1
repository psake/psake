Task 'Clean' @{
    Description = 'Clean build artifacts'
    Action      = { "Cleaned!" }
}

Task 'Build' @{
    DependsOn = 'Clean'
    Action    = { "Built!" }
}

Task 'Default' @{ DependsOn = 'Build' }
