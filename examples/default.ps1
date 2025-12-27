# Use script-scoped variables to avoid PSScriptAnalyzer warnings
properties {
  $script:testMessage = 'Executed Test!'
  $script:compileMessage = 'Executed Compile!'
  $script:cleanMessage = 'Executed Clean!'
}

task default -depends Test

task Test -depends Compile, Clean {
  $testMessage
}

task Compile -depends Clean {
  $compileMessage
}

task Clean {
  $cleanMessage
}

task ? -Description "Helper to display task info" {
  Write-Documentation
}
