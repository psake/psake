Task default -depends Test

Task Test {
    [string]$currentPath = Get-Location
    [string]$parentPath = Split-Path $currentPath -Parent
    [string[]]$global:locations = @()
    [string[]]$expected = "$currentPath,$parentPath,$parentPath,$parentPath,$currentPath"
    [scriptblock]$cmd = {
        $global:locations += Get-Location
        throw "forced error"
    }

    $global:locations += Get-Location
    try {
        Exec -cmd $cmd -maxRetries 2 -workingDirectory $parentPath
    }
    catch {}
    $global:locations += Get-Location

     [string]$actual = $global:locations -join ","
     $actual = $actual.ToLower()
     Assert ($actual -eq $expected) "Expected: '$expected' Actual: '$actual'"
}