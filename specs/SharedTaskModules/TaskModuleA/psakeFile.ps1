
properties {
    $x = 'asdf'
    $y = 'something'
}

task TaskAFromModuleA {
    'Executing [TaskA] from module [TaskModuleA] version [0.1.0]'

    Write-Output $x
    Write-Output $y
}

task tasky -depends taskz {
    "I'm task Y"
}

task taskz {
    "I'm task z"
} -depends 'TaskBFromModuleB'

#task TaskBFromModuleB -FromModule TaskModuleB -Version 0.1.0
