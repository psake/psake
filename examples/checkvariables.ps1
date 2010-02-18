properties {
	$x = 1
	$y = 2
}

FormatTaskName "[{0}]"

task default -depends Verify 

task Verify -description "This task verifies psake's variables" {

	#Verify the exported "psake" module variable 
	Assert (Test-Path "variable:\psake") "'psake' variable was not exported from module"
	
	Assert ($variable:psake.ContainsKey("build_success")) "psake variable does not contain 'build_success'"
	Assert ($variable:psake.ContainsKey("use_exit_on_error")) "psake variable does not contain 'use_exit_on_error'"
	Assert ($variable:psake.ContainsKey("log_error")) "psake variable does not contain 'log_error'"
	Assert ($variable:psake.ContainsKey("version")) "psake variable does not contain 'version'"
	Assert ($variable:psake.ContainsKey("build_script_file")) "psake variable does not contain 'build_script_file'"
	Assert ($variable:psake.ContainsKey("framework_version")) "psake variable does not contain 'framework_version'"
	
	Assert (!$variable:psake.build_success) 'psake.build_success should be $false'
	Assert (!$variable:psake.use_exit_on_error) 'psake.use_exit_on_error should be $false'
	Assert (!$variable:psake.log_error) 'psake.log_error should be $false'
	Assert (![string]::IsNullOrEmpty($variable:psake.version)) 'psake.version was null or empty'
	Assert ($variable:psake.build_script_file -ne $null) '$psake.build_script_file was null' 
	Assert ($variable:psake.build_script_file.Name -eq "VerifyVariables.ps1") ("psake variable: {0} was not equal to 'VerifyVariables.ps1'" -f $psake.build_script_file.Name)
	Assert (![string]::IsNullOrEmpty($variable:psake.framework_version)) 'psake variable: $psake.framework_version was null or empty'

	#Verify script-level variables - only available when a script is being run
	Assert ($variable:tasks.Count -ne 0) 'psake variable: $tasks had length zero'
	Assert ($variable:properties.Count -ne 0) 'psake variable: $properties had length zero'
	Assert ($variable:includes.Count -eq 0) 'psake variable: $includes should have had length zero'	
	Assert ($variable:formatTaskNameString -eq "[{0}]") 'psake variable: $formatTaskNameString was not set correctly'
	Assert ($variable:currentTaskName -eq "Verify") 'psake variable: $currentTaskName was not set correctly'
}