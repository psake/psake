task validate-psake -description 'Run example psake scripts to validate behavior' {
	trap {
		Set-Location 'package'
		throw;
	}
	Set-Location '..\'
	.\psake-buildTester.ps1
	Set-Location 'package'
}

task package-psake -description 'Packages all psake scripts, docs, and example scripts into a zip file' -depends update-psake-version {
	$version = (cat Version.inc)
	$zipFile = "psake v$version.zip"
	
	if (test-path $zipFile) {
		Remove-Item $zipFile
	}

	.\7za a "$zipFile" ..\ -r "-x@Excluded.txt"
}

task update-psake-version -description 'Updates version references in psake script' {
	$previousVersion = New-Object System.Version (cat Version.inc)
	$newVersion = New-Object System.Version $previousVersion.Major,($previousVersion.Minor+1)
	
	$first = $true
	$outputFile = '..\psake.ps1'
	foreach ($line in (cat ..\psake.ps1)) {
		$fileLine = [regex]::Replace($line, $previousVersion, $newVersion);	
		if ($first) {
			$fileLine | Out-File $outputFile 
			$first = $false
		} else {
			$fileLine | Out-File $outputFile -append
		}
	}
	
	$newVersion.ToString() | Out-File Version.inc
}

task deploy-psake -description 'Deploys to code.google.com/p/psake' {
}