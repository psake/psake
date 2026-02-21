properties {
  $script:runTaskA = $false
  $script:taskBSucceded = $true
}

task default -depends TaskC

task TaskA -precondition { $runTaskA -eq $true } {
  "TaskA executed"
}

task TaskB -postcondition { $taskBSucceded -eq $true } {
  "TaskB executed"
}

task TaskC -depends TaskA,TaskB {
  "TaskC executed."
}