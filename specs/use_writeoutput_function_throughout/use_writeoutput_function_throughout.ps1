task default -depends Task1

task TaskA -alias Task1 -preaction { "something" | Out-Null } -postaction {"something" | Out-Null} -precondition {1 -eq 1} {"something" | Out-Null}

task TaskB -precondition {0 -eq 1} {}

task TaskC -continueonerror {throw "Forced error"}
