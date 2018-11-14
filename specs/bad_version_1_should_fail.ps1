task default -depends 'TaskAFromModuleA'

task 'TaskAFromModuleA' -FromModule TaskModuleA -minimumVersion 0.2.0
