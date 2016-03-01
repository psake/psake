Task default -depends CheckStructuredDocs

function Assert-EqualArrays($a, $b, $message)
{
    $differences = @(Compare-Object $a $b -SyncWindow 0)
    if ($differences.Length -gt 0)
    {
        $differences
    }
    Assert ($differences.Length -eq 0) "$message : $($differences.Length) differences found."
}

function Assert-TaskEqual($t1, $t2)
{
    Assert ($t1.Name -eq $t2.Name)                "Task names do not match: $($t1.Name) vs $($t2.Name)"
    Assert ($t1.Alias -eq $t2.Alias)              "Task aliases do not match for task $($t1.Name): $($t1.Alias) vs $($t2.Alias)"
    Assert ($t1.Description -eq $t2.Description)  "Task descriptions do not match for task $($t1.Name): $($t1.Description) vs $($t2.Description)"
    Assert ($t1.Default -eq $t2.Default)          "Task 'defaults' do not match for task $($t1.Name): $($t1.Default) vs $($t2.Default)"

    Assert-EqualArrays $t1.DependsOn $t2.DependsOn "Task dependencies do not match for task $($t1.Name)"
}

Task CheckStructuredDocs {
    
    $tasks = Invoke-psake .\nested\docs.ps1 -structuredDocs
    $tasks = $tasks | sort -Property Name

    Assert ($tasks.Length -eq 7) 'Unexpected number of tasks.'

    Assert-TaskEqual $tasks[0] ([pscustomobject]@{Name = 'Compile';          Alias = '';   Description = '';                    DependsOn = @('CompileSolutionA','CompileSolutionB'); Default = $true;})
    Assert-TaskEqual $tasks[1] ([pscustomobject]@{Name = 'CompileSolutionA'; Alias = '';   Description = 'Compiles solution A'; DependsOn = @();                                      Default = $null;})
    Assert-TaskEqual $tasks[2] ([pscustomobject]@{Name = 'CompileSolutionB'; Alias = '';   Description = '';                    DependsOn = @();                                      Default = $null;})
    Assert-TaskEqual $tasks[3] ([pscustomobject]@{Name = 'default';          Alias = '';   Description = '';                    DependsOn = @('Compile','Test');                      Default = $null;})
    Assert-TaskEqual $tasks[4] ([pscustomobject]@{Name = 'IntegrationTests'; Alias = '';   Description = '';                    DependsOn = @();                                      Default = $null;})
    Assert-TaskEqual $tasks[5] ([pscustomobject]@{Name = 'Test';             Alias = '';   Description = '';                    DependsOn = @('UnitTests','IntegrationTests');        Default = $true;})
    Assert-TaskEqual $tasks[6] ([pscustomobject]@{Name = 'UnitTests';        Alias = 'ut'; Description = '';                    DependsOn = @();                                      Default = $null;})
}
