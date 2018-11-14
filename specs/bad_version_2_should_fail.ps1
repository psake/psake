task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleB' -Frommodule TaskModuleB -maximumVersion 0.0.5
