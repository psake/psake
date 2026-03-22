
Properties {
    $x = 42
}

Task default -Depends 'TaskAFromModuleA'

Task 'TaskAFromModuleA' -FromModule TaskModuleA -Depends TaskAFromModuleB

Task 'TaskAFromModuleB' -FromModule TaskModuleB -MinimumVersion 0.2.0 -Depends xxx -ContinueOnError

Task xxx {
    throw 'oops'
}

Task 'TaskbFromModuleA' -FromModule TaskModuleA -MinimumVersion 0.0.1 -MaximumVersion 0.2.0

Task 'TaskbFromModuleB' -FromModule TaskModuleB -MinimumVersion 0.2.0 -MaximumVersion 0.3.0
