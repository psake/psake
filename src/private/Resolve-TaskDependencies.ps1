function Resolve-TaskDependencies {
    <#
    .SYNOPSIS
    Performs a depth-first topological sort with cycle detection for a single task.

    .DESCRIPTION
    Recursively walks the dependency graph from the given task key, appending
    each task to $Order in post-order (dependencies before dependents).
    Detected validation errors are written to the pipeline.

    .OUTPUTS
    [string] Validation error messages, if any.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TaskKey,

        [Parameter(Mandatory = $true)]
        [hashtable]$TaskMap,

        [Parameter(Mandatory = $true)]
        [hashtable]$Aliases,

        [Parameter(Mandatory = $False)]
        [hashtable]$InStack = @{},

        [Parameter(Mandatory = $False)]
        [hashtable]$Visited = @{},

        [Parameter(Mandatory = $False)]
        [System.Collections.Generic.List[string]]
        $Order = [System.Collections.Generic.List[string]]::new()
    )
    begin {
        Write-Debug "Resolving dependencies for task(s): $($TaskKey -join ', ')"
        Write-Debug "Current stack: $($InStack.Keys -join ' -> ')"
        $ValidationErrors = @()
    }
    process {
        foreach ($key in $TaskKey) {
            if ($InStack.ContainsKey($key)) {
                $ValidationErrors += "Circular reference found for task '$key'."
                return
            }
            if ($Visited.ContainsKey($key)) {
                return
            }
            Write-Debug "Visited tasks: $($Visited.Keys -join ', ')"


            $InStack[$key] = $true

            $task = $TaskMap[$key]
            if ($null -eq $task) {
                $ValidationErrors += "Task '$key' does not exist."
                $InStack.Remove($key)
                return
            }

            foreach ($dep in $task.DependsOn) {
                $depKey = $dep.ToLower()
                # Resolve alias
                if ($Aliases.ContainsKey($depKey)) {
                    $depKey = $Aliases[$depKey].Name.ToLower()
                }
                if (-not $TaskMap.ContainsKey($depKey)) {
                    $ValidationErrors += "Task '$dep' (dependency of '$key') does not exist."
                    continue
                }
                $resolved = Resolve-TaskDependencies -TaskKey $depKey -TaskMap $TaskMap -Aliases $Aliases -InStack $InStack -Visited $Visited -Order $Order
                $ValidationErrors += $resolved.ValidationErrors
            }

            $InStack.Remove($key)
            $Visited[$key] = $true
            $Order.Add($key)
        }
    }

    end {
        Write-Debug "Finished resolving dependencies for task(s): $($TaskKey -join ', ')"
        return @{
            'Order'            = $Order
            'Visited'          = $Visited
            'InStack'          = $InStack
            'ValidationErrors' = $ValidationErrors
        }
    }
}
