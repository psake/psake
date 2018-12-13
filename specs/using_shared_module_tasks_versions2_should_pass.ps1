task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -minimumVersion 0.1.0

task 'TaskAFromModuleB' -Frommodule TaskModuleB -minimumVersion 0.2.0

task 'TaskBFromModuleA' -FromModule TaskModuleA -Version 0.1.0
