properties {
  $script:testMessage = 'Executed Test!'
  $script:compileMessage = 'Executed Compile!'
  $script:cleanMessage = 'Executed Clean!'
}

task default -depends Test

formatTaskName "-------{0}-------"

task Test -depends Compile, Clean {
  $testMessage
}

task Compile -depends Clean {
  $compileMessage
}

task Clean {
  $cleanMessage
}
