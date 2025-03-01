[string[]]$files = @("TestFile1.ps1","TestFile2.ps1");

Out-File -FilePath "TestFile1.ps1" -InputObject "function Test-Function1 { return 1; }";
Out-File -FilePath "TestFile2.ps1" -InputObject "function Test-Function2 { return 2; }";

$files | Include;

Task default -depends Test;

BuildTearDown {
    @("TestFile1.ps1","TestFile2.ps1","Function:\Test-Function1","Function:\Test-Function2") | ForEach-Object {Remove-Item $_;} | Out-Null;
}

Task Test {
    Assert ($(Test-Path "Function:\Test-Function1")) "Test-Function1 is not accessible";
    Assert ($(Test-Path "Function:\Test-Function2")) "Test-Function2 is not accessible";
}

