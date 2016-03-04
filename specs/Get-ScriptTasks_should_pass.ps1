Task default -depends CheckGetScriptTasks

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

    Assert-EqualArrays $t1.DependsOn $t2.DependsOn "Task dependencies do not match for task $($t1.Name)"
}

function HelloYou
{
    Write-Host 'Hello you'
}

Task CheckGetScriptTasks {
    
    $tasks = Get-ScriptTasks .\nested\docs.ps1
    $tasks = $tasks | sort -Property Name

    Assert ($tasks.Length -eq 7) 'Unexpected number of tasks.'

    Assert-TaskEqual $tasks[0] ([pscustomobject]@{Name = 'Compile';          Alias = '';   Description = '';                    DependsOn = @('CompileSolutionA','CompileSolutionB');})
    Assert-TaskEqual $tasks[1] ([pscustomobject]@{Name = 'CompileSolutionA'; Alias = '';   Description = 'Compiles solution A'; DependsOn = @();                                     })
    Assert-TaskEqual $tasks[2] ([pscustomobject]@{Name = 'CompileSolutionB'; Alias = '';   Description = '';                    DependsOn = @();                                     })
    Assert-TaskEqual $tasks[3] ([pscustomobject]@{Name = 'default';          Alias = '';   Description = '';                    DependsOn = @('Compile','Test');                     })
    Assert-TaskEqual $tasks[4] ([pscustomobject]@{Name = 'IntegrationTests'; Alias = '';   Description = '';                    DependsOn = @();                                     })
    Assert-TaskEqual $tasks[5] ([pscustomobject]@{Name = 'Test';             Alias = '';   Description = '';                    DependsOn = @('UnitTests','IntegrationTests');       })
    Assert-TaskEqual $tasks[6] ([pscustomobject]@{Name = 'UnitTests';        Alias = 'ut'; Description = '';                    DependsOn = @();                                     })
}
