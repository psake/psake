properties {
  $x = 1
}

FormatTaskName "[{0}]"

task default -depends Verify 

task Verify -description "This task verifies psake's variables" {

  #Verify the exported module variables
  cd variable:
  Assert (Test-Path "psake") "variable psake was not exported from module"
  
  Assert ($psake.ContainsKey("build_success")) "psake variable does not contain 'build_success'"
  Assert ($psake.ContainsKey("version")) "psake variable does not contain 'version'"
  Assert ($psake.ContainsKey("build_script_file")) "psake variable does not contain 'build_script_file'"
  Assert ($psake.ContainsKey("framework_version")) "psake variable does not contain 'framework_version'"
  Assert ($psake.ContainsKey("build_script_dir")) "psake variable does not contain 'build_script_dir'"  
  
  Assert (!$psake.build_success) 'psake.build_success should be $false'
  Assert ($psake.version) 'psake.version was null or empty'
  Assert ($psake.build_script_file) '$psake.build_script_file was null' 
  Assert ($psake.build_script_file.Name -eq "writing_psake_variables_should_pass.ps1") ("psake variable: {0} was not equal to 'writing_psake_variables_should_pass.ps1'" -f $psake.build_script_file.Name)
  Assert ($psake.build_script_dir) 'psake variable: $psake.build_script_dir was null or empty'
  Assert ($psake.framework_version) 'psake variable: $psake.framework_version was null or empty'

  Assert ($psake.context.Count -eq 1) '$psake.context should have had a length of one (1) during script execution'
}