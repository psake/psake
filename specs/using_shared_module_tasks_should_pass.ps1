
properties {
    $x = 42
}

task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -depends TaskAFromModuleB

task 'TaskAFromModuleB' -Frommodule TaskModuleB -minimumVersion 0.2.0 -depends xxx -continueOnError

task xxx {
    throw 'oops'
}

task 'TaskbFromModuleA' -FromModule TaskModuleA -minimumVersion 0.0.1 -maximumVersion 0.2.0

task 'TaskbFromModuleB' -Frommodule TaskModuleB -minimumVersion 0.2.0 -maximumVersion 0.3.0
