task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -minimumVersion 0.1.0 -maximumVersion 0.1.0

task 'TaskAFromModuleB' -Frommodule TaskModuleB -minimumVersion 0.2.0 -lessThanVersion 0.3.0

task 'TaskbFromModuleA' -FromModule TaskModuleA -maximumVersion 0.1.0

task 'TaskbFromModuleB' -Frommodule TaskModuleB -lessThanVersion 0.3.0
