$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

properties {
    # The spec tests add a 'container` hashtable for use by other tests
    # Since we've set strict mode here, we need to define this variable
    # even though we won't use it for this particular test
    $container = @{}
}

Task default -depends task2

Task Step1 -alias task1 {
    'Hi from Step1 (task1)'
}

Task Step2 -alias task2 -depends task1 {
    'Hi from Step2 (task2)'
}
