Properties @{
    Config = 'Release'
    Output = 'artifacts'
}

Task 'default' -depends 'Verify'

Task 'Verify' {
    Assert ($Config -eq 'Release') 'Config should be Release'
    Assert ($Output -eq 'artifacts') 'Output should be artifacts'
}
