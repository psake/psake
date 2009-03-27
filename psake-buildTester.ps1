powershell -nologo -noprofile -command {
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
		
		$testResults | ft -auto
		
		$failed = $testResults | ? { $_.Result -eq "Failed" }
		if ($failed) { exit(1) }
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

	runBuilds
}