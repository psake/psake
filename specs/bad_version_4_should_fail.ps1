task default -depends 'TaskAFromModuleA'

task 'TaskbFromModuleB' -Frommodule TaskModuleB -lessThanVersion 0.3.0
