function runBuilds{
	$buildFiles = dir examples\*.ps1
	$testResults = @()	
	
	#Add a fake build file to the $buildFiles array so that we can verify
	#that Invoke-psake fails
    $non_existant_buildfile = "" | select Name, FullName
    $non_existant_buildfile.Name = "bad-non_existant_buildfile.ps1"
    $non_existant_buildfile.FullName = "c:\bad-non_existant_buildfile.ps1"
    $buildFiles += $non_existant_buildfile
    
	foreach($buildFile in $buildFiles) {					
		$testResult = "" | select Name, Result 
		$testResult.Name = $buildFile.Name
		
		if ($buildFile.Name -eq "parameters.ps1")
		{
			Invoke-psake $buildFile.FullName -Parameters @{'p1'='v1'; 'p2'='v2'} | Out-Null			
		}
		else
		{
			Invoke-psake $buildFile.FullName | Out-Null			
		}
		$testResult.Result = (getResult $buildFile.Name $psake.build_success)
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

Remove-Module psake -ea SilentlyContinue

Import-Module .\psake.psm1

$results = runBuilds

Remove-Module psake

$results | Sort 'Name' | Format-Table -Auto 

$failed = $results | ? { $_.Result -eq "Failed" }
if ($failed) {
	write-host "One of the builds failed" -ForeGroundColor 'RED'
	exit 1
} else {
	exit 0
}	
