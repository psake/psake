task default -depends Test

task Test -depends Compile, Clean { 
  Write-Host "Executed Test!"
}

task Compile -depends Clean { 
  Write-Host "Executed Compile!"
}

task Clean { 
  Write-Host "Executed Clean!"
}