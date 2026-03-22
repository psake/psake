Task 'default' -depends 'A'

Task 'A' -depends 'B' {
    "Task A"
}

Task 'B' -depends 'A' {
    "Task B"
}
