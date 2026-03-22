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
        [Parameter(Mandatory)]
        [string]$TaskKey,

        [Parameter(Mandatory)]
        [hashtable]$TaskMap,

        [Parameter(Mandatory)]
        [hashtable]$Aliases,

        [Parameter(Mandatory)]
        [hashtable]$InStack,

        [Parameter(Mandatory)]
        [hashtable]$Visited,

        [Parameter(Mandatory)]
        [System.Collections.Generic.List[string]]$Order
    )

    if ($InStack.ContainsKey($TaskKey)) {
        Write-Output "Circular reference found for task '$TaskKey'."
        return
    }
    if ($Visited.ContainsKey($TaskKey)) {
        return
    }

    $InStack[$TaskKey] = $true

    $task = $TaskMap[$TaskKey]
    if ($null -eq $task) {
        Write-Output "Task '$TaskKey' does not exist."
        $InStack.Remove($TaskKey)
        return
    }

    foreach ($dep in $task.DependsOn) {
        $depKey = $dep.ToLower()
        # Resolve alias
        if ($Aliases.ContainsKey($depKey)) {
            $depKey = $Aliases[$depKey].Name.ToLower()
        }
        if (-not $TaskMap.ContainsKey($depKey)) {
            Write-Output "Task '$dep' (dependency of '$TaskKey') does not exist."
            continue
        }
        Resolve-TaskDependencies -TaskKey $depKey -TaskMap $TaskMap -Aliases $Aliases -InStack $InStack -Visited $Visited -Order $Order
    }

    $InStack.Remove($TaskKey)
    $Visited[$TaskKey] = $true
    $Order.Add($TaskKey)
}
