task default -depends 'TaskAFromModuleA'

task 'TaskbFromModuleA' -FromModule TaskModuleA -Version 0.5.0
