Task 'default' -depends 'Build'

Task 'Build' -depends 'NonExistentTask' {
    "This should fail because NonExistentTask doesn't exist"
}
