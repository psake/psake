Properties {
  $x = 1
  $y = 2
}

FormatTaskName "[{0}]"

Task default -Depends Verify 

Task Verify -Description "This task verifies psake's variables" {
  Assert (Test-Path 'variable:\psake') "'psake' variable was not exported from module"
  Assert ($psake.ContainsKey("build_success")) "psake variable does not contain 'build_success'"
  Assert ($psake.ContainsKey("version")) "psake variable does not contain 'version'"
  Assert ($psake.ContainsKey("build_script_file")) "psake variable does not contain 'build_script_file'"
  Assert ($psake.ContainsKey("framework_version")) "psake variable does not contain 'framework_version'"
  Assert ($psake.ContainsKey("build_script_dir")) "'psake' variable does not contain key 'build_script_dir'"  
  Assert ($psake.ContainsKey("config")) "'psake' variable does not contain key 'config'"  

  Assert (!$psake.build_success) 'psake.build_success should be $false'
  Assert ($psake.version) 'psake.version was null or empty'
  Assert ($psake.build_script_file) '$psake.build_script_file was null'
  Assert ($psake.build_script_file.Name -eq "checkvariables.ps1") ("psake variable: {0} was not equal to 'checkvariables.ps1'" -f $psake.build_script_file.Name)
  Assert ($psake.build_script_dir) '$psake variable: $psake.build_script_dir was null or empty'
  Assert ($psake.framework_version) 'psake variable: $psake.framework_version was null or empty'

  Assert ($psake.config) '$psake.config is $null'
  Assert ($psake.config.defaultBuildFileName -eq "default.ps1") '$psake.config.defaultBuildFileName not equal to "default.ps1"'
  Assert ($psake.config.taskNameFormat -eq "Executing {0}") '$psake.config.taskNameFormat not equal to "Executing {0}"'
  Assert ($psake.config.verboseError -eq $false) '$psake.config.verboseError not equal to $true'
  Assert ($psake.config.modules) '$psake.config.modules is $null'

  Assert ($psake.context.Peek().tasks.Count -ne 0) 'psake variable: $tasks had length zero'
  Assert ($psake.context.Peek().properties.Count -ne 0) 'psake variable: $properties had length zero'
  Assert ($psake.context.Peek().includes.Count -eq 0) 'psake variable: $includes should have had length zero'
  Assert ($psake.context.Peek().formatTaskNameString -ne "") 'psake variable: $formatTaskNameString was not set correctly'
  Assert ($psake.context.Peek().currentTaskName -eq "Verify") 'psake variable: $currentTaskName was not set correctly'
}