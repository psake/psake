function runBuilds{
	$buildFiles = dir examples\*.ps1
	$testResults = @()	
	
	foreach($buildFile in $buildFiles) {					
		$testResult = "" | select Name, Result 
		$testResult.Name = $buildFile.Name
		Run-psake $buildFile -noexit | Out-Null			
		$testResult.Result = (getResult $buildFile.Name $global:psake_buildSucceeded)
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
$results | ft -auto
	
$failed = $results | ? { $_.Result -eq "Failed" }
if ($failed) {
	"One of the builds failed"
	exit 1
} else {
	exit 0
}	
