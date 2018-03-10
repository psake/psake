
properties {
    $x = 42
}

task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -depends TaskAFromModuleB

task 'TaskAFromModuleB' -Frommodule TaskModuleB -Version 0.2.0 -depends xxx -continueOnError

task xxx {
    throw 'oops'
}
