properties {
	$p1 = $null
	$p2 = $null
}

task default -depends TestParams

task TestParams { 
  Assert ($p1 -ne $null) "p1 should not be null"
  Assert ($p2 -ne $null) "p2 should not be null"
}