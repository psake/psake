powershell -nologo -noprofile -output "Text" -command {
	function runBuilds{
		$buildFiles = dir examples\*.ps1
		$testResults = @()	
		
		foreach($buildFile in $buildFiles) {					
			$testResult = "" | select Name, Result 
			$testResult.Name = $buildFile.Name
			.\psake.ps1 $buildFile | Out-Null			
			$testResult.Result = (getResult $buildFile.Name $?)
			$testResults += $testResult 			
		}
		return $testResults
	}
	
	function getResult([string]$fileName, [bool]$buildSucceeded) {		
		if ($fileName.StartsWith("bad")) {
			if (!$buildSucceeded) {
				"Passed"
			} 
			else {
				"Failed"
			}	
		}
		else {
			if ($buildSucceeded) {
				"Passed"
			} 
			else {
				"Failed"
			}
		}
	}

	$results = runBuilds
	#$results | ft -auto
		
	$failed = $Results | ? { $_.Result -eq "Failed" }
	if ($failed) {exit 1} else {exit 0}	
}