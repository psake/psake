properties {
  $script:testMessage = 'Executed Test!'
  $script:compileMessage = 'Executed Compile!'
  $script:cleanMessage = 'Executed Clean!'
}

task default -depends Test

formatTaskName {
  param($taskName)
  write-host $taskName -foregroundcolor Green
}

task Test -depends Compile, Clean {
  $testMessage
}

task Compile -depends Clean {
  $compileMessage
}

task Clean {
  $cleanMessage
}
