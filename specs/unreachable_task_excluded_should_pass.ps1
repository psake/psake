Task 'Clean' @{ Action = { "Cleaned!" } }

Task 'Build' @{
    DependsOn = 'Clean'
    Action    = { "Built!" }
}

Task 'Default' @{ DependsOn = 'Build' }

# This task is registered but never depended upon — should not appear in a compiled plan
Task 'Deploy' @{ Action = { "Deployed!" } }
