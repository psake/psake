Task default -depends Test

Task Test {
    [string[]]$global:locations = @()
    [string[]]$expected = "env:\,variable:\,variable:\,variable:\,env:\"
    [scriptblock]$cmd = {
        $global:locations += Get-Location
        throw "forced error"
    }
    Set-Location "env:"

    $global:locations += Get-Location
    try {
        Exec -cmd $cmd -maxRetries 2 -workingDirectory "variable:"
    }
    catch {}
    $global:locations += Get-Location

     [string]$actual = $global:locations -join ","
     $actual = $actual.ToLower()
     Assert ($actual -eq $expected) "Expected: '$expected' Actual: '$actual'"
}