BeforeDiscovery {
    if ($null -eq $env:BHProjectName) {
        .\build.ps1 -Task Build
    }
    $manifest = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
    $outputDir = Join-Path -Path $env:BHProjectPath -ChildPath 'output'
    $outputModDir = Join-Path -Path $outputDir -ChildPath $env:BHProjectName
    $outputModVerDir = Join-Path -Path $outputModDir -ChildPath $manifest.ModuleVersion
    $outputModVerManifest = Join-Path -Path $outputModVerDir -ChildPath "$($env:BHProjectName).psd1"

    # Get module commands
    # Remove all versions of the module from the session. Pester can't handle multiple versions.
    Get-Module $env:BHProjectName | Remove-Module -Force -ErrorAction Ignore
    Import-Module -Name $outputModVerManifest -Verbose:$false -ErrorAction Stop
}
Describe 'Resolve-TaskDependencies' {

    Context 'Single task with no dependencies' {
        It 'Adds the task to the order' {
            InModuleScope "$env:BHProjectName" {
                $task = [PsakeTask]@{ Name = 'build' }
                $taskMap = @{ 'build' = $task }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('build') -TaskMap $taskMap -Aliases @{} -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                $order | Should -HaveCount 1
                $order[0] | Should -Be 'build'
            }
        }
    }

    Context 'Linear dependency chain' {
        It 'Resolves tasks in post-order (dependencies before dependents)' {
            InModuleScope "$env:BHProjectName" {
                $taskC = [PsakeTask]@{ Name = 'c' }
                $taskB = [PsakeTask]@{ Name = 'b'; DependsOn = @('c') }
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('b') }
                $taskMap = @{ 'a' = $taskA; 'b' = $taskB; 'c' = $taskC }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{} -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                $order | Should -HaveCount 3
                $order[0] | Should -Be 'c'
                $order[1] | Should -Be 'b'
                $order[2] | Should -Be 'a'
            }
        }
    }

    Context 'Diamond dependency' {
        It 'Visits shared dependency exactly once' {
            InModuleScope "$env:BHProjectName" {
                $taskD = [PsakeTask]@{ Name = 'd' }
                $taskB = [PsakeTask]@{ Name = 'b'; DependsOn = @('d') }
                $taskC = [PsakeTask]@{ Name = 'c'; DependsOn = @('d') }
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('b', 'c') }
                $taskMap = @{ 'a' = $taskA; 'b' = $taskB; 'c' = $taskC; 'd' = $taskD }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{} -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                ($order | Where-Object { $_ -eq 'd' }) | Should -HaveCount 1
                $order.IndexOf('d') | Should -BeLessThan $order.IndexOf('b')
                $order.IndexOf('d') | Should -BeLessThan $order.IndexOf('c')
                $order.IndexOf('b') | Should -BeLessThan $order.IndexOf('a')
                $order.IndexOf('c') | Should -BeLessThan $order.IndexOf('a')
            }
        }
    }

    Context 'Multiple independent start tasks' {
        It 'Resolves all start tasks into the order' {
            InModuleScope "$env:BHProjectName" {
                $taskA = [PsakeTask]@{ Name = 'a' }
                $taskB = [PsakeTask]@{ Name = 'b' }
                $taskMap = @{ 'a' = $taskA; 'b' = $taskB }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('a', 'b') -TaskMap $taskMap -Aliases @{} -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                $order | Should -HaveCount 2
                $order | Should -Contain 'a'
                $order | Should -Contain 'b'
            }
        }
    }

    Context 'Alias resolution' {
        It 'Resolves a dependency specified by alias to the canonical task name' {
            InModuleScope "$env:BHProjectName" {
                $taskB = [PsakeTask]@{ Name = 'b' }
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('balias') }
                $taskMap = @{ 'a' = $taskA; 'b' = $taskB }
                $aliasTarget = [PsakeTask]@{ Name = 'b' }
                $aliases = @{ 'balias' = $aliasTarget }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases $aliases -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                $order | Should -Contain 'b'
                $order | Should -Contain 'a'
                $order.IndexOf('b') | Should -BeLessThan $order.IndexOf('a')
            }
        }
    }

    Context 'Circular dependency' {
        It 'Returns a circular reference error message' {
            InModuleScope "$env:BHProjectName" {
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('b') }
                $taskB = [PsakeTask]@{ Name = 'b'; DependsOn = @('a') }
                $taskMap = @{ 'a' = $taskA; 'b' = $taskB }

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{}
                $errors = $resolved.ValidationErrors

                $errors | Should -Not -BeNullOrEmpty
                ($errors -join ' ') | Should -Match 'Circular'
            }
        }

        It 'Returns a circular reference error for a self-referencing task' {
            InModuleScope "$env:BHProjectName" {
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('a') }
                $taskMap = @{ 'a' = $taskA }

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{}
                $errors = $resolved.ValidationErrors

                $errors | Should -Not -BeNullOrEmpty
                ($errors -join ' ') | Should -Match 'Circular'
            }
        }
    }

    Context 'Missing task' {
        It 'Returns an error when the start task is not in the TaskMap' {
            InModuleScope "$env:BHProjectName" {
                $resolved = Resolve-TaskDependencies -TaskKey @('nonexistent') -TaskMap @{} -Aliases @{}
                $errors = $resolved.ValidationErrors

                $errors | Should -Not -BeNullOrEmpty
                ($errors -join ' ') | Should -Match 'does not exist'
            }
        }

        It 'Returns an error when a dependency is not in the TaskMap' {
            InModuleScope "$env:BHProjectName" {
                $taskA = [PsakeTask]@{ Name = 'a'; DependsOn = @('missing') }
                $taskMap = @{ 'a' = $taskA }

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{}
                $errors = $resolved.ValidationErrors

                $errors | Should -Not -BeNullOrEmpty
                ($errors -join ' ') | Should -Match 'does not exist'
            }
        }
    }

    Context 'Previously visited tasks' {
        It 'Does not add already-visited tasks when called with shared state' {
            InModuleScope "$env:BHProjectName" {
                $taskA = [PsakeTask]@{ Name = 'a' }
                $taskMap = @{ 'a' = $taskA }
                $visited = @{ 'a' = $true }
                $order = [System.Collections.Generic.List[string]]::new()

                $resolved = Resolve-TaskDependencies -TaskKey @('a') -TaskMap $taskMap -Aliases @{} -Visited $visited -Order $order
                $errors = $resolved.ValidationErrors

                $errors | Should -BeNullOrEmpty
                $order | Should -HaveCount 0
            }
        }
    }
}
