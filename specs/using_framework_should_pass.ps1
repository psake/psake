task default -depends FrameworkFunction

task FrameworkFunction  {
  if ( $IsMacOS -OR $IsLinux ) {}
  else {
	  AssertFramework -Framework '2.0' -AcceptableRegEx '2\.0'
	  AssertFramework -Framework '3.5' -AcceptableRegEx '3\.5'
	  AssertFramework -Framework '4.0' -AcceptableRegEx '4\.[0-9]\.'
  }
}

function AssertFramework{
	param(
		[string]$framework,
		[string]$acceptableregex
	)
	Framework $framework
	$msBuildVersion = msbuild /version

  $comparisonRegEx = "microsoft \(r\) build engine version $acceptableregex"

	Assert ($msBuildVersion[0].ToLower() -match $comparisonRegEx) '$msBuildVersion does not start with "$framework"'
}
