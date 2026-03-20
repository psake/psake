function Compile-BuildPlan {
    <#
    .SYNOPSIS
    Compiles a build plan from the current psake context.

    .DESCRIPTION
    Takes the registered tasks from the current context and produces a
    PsakeBuildPlan with validated dependency graph and execution order.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BuildFile,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$TaskList
    )

    Write-Debug "Compiling build plan for '$BuildFile' with tasks: $($TaskList -join ', ')"
    $currentContext = $psake.Context.Peek()

    # Validate Version declaration if present
    if ($currentContext.ContainsKey('requiredVersion') -and $currentContext.requiredVersion) {
        $psakeMajor = [int]($psake.version.Split('.')[0])
        if ($currentContext.requiredVersion -ne $psakeMajor) {
            throw "Build script requires psake version $($currentContext.requiredVersion) but running version $($psake.version)."
        }
    }

    $plan = [PsakeBuildPlan]::new()
    $plan.BuildFile = $BuildFile
    $plan.CompiledAt = [datetime]::UtcNow
    $plan.CacheDir = Join-Path (Split-Path $BuildFile -Parent) '.psake' 'cache'
    $plan.ValidationErrors = @()

    # Build TaskMap from context
    foreach ($key in $currentContext.tasks.Keys) {
        Write-Debug "Adding task '$key' to build plan from context."
        $plan.TaskMap[$key] = $currentContext.tasks[$key]
    }

    # Resolve aliases
    foreach ($key in $currentContext.aliases.Keys) {
        if (-not $plan.TaskMap.ContainsKey($key)) {
            $plan.TaskMap[$key] = $currentContext.aliases[$key]
        }
    }

    $plan.Tasks = @($plan.TaskMap.Values)

    # Resolve the starting tasks
    $startTasks = @()
    if ($TaskList -and $TaskList.Count -gt 0) {
        foreach ($taskName in $TaskList) {
            $taskKey = $taskName.ToLower()
            # Check aliases
            if ($currentContext.aliases.ContainsKey($taskKey)) {
                $taskKey = $currentContext.aliases[$taskKey].Name.ToLower()
            }
            if (-not $plan.TaskMap.ContainsKey($taskKey)) {
                $plan.ValidationErrors += "Task '$taskName' does not exist."
            } else {
                $startTasks += $taskKey
            }
        }
    } elseif ($plan.TaskMap.ContainsKey('default')) {
        $startTasks = @('default')
    } else {
        $plan.ValidationErrors += "'default' task required."
    }

    if ($plan.ValidationErrors.Count -gt 0) {
        $plan.IsValid = $false
        return $plan
    }

    # Topological sort with cycle detection
    $visited = @{}
    $inStack = @{}
    $order = [System.Collections.Generic.List[string]]::new()

    function Resolve-TaskDependencies {
        param([string]$TaskKey)

        if ($inStack.ContainsKey($TaskKey)) {
            $plan.ValidationErrors += "Circular reference found for task '$TaskKey'."
            return
        }
        if ($visited.ContainsKey($TaskKey)) {
            return
        }

        $inStack[$TaskKey] = $true

        $task = $plan.TaskMap[$TaskKey]
        if ($null -eq $task) {
            $plan.ValidationErrors += "Task '$TaskKey' does not exist."
            $inStack.Remove($TaskKey)
            return
        }

        foreach ($dep in $task.DependsOn) {
            $depKey = $dep.ToLower()
            # Resolve alias
            if ($currentContext.aliases.ContainsKey($depKey)) {
                $depKey = $currentContext.aliases[$depKey].Name.ToLower()
            }
            if (-not $plan.TaskMap.ContainsKey($depKey)) {
                $plan.ValidationErrors += "Task '$dep' (dependency of '$TaskKey') does not exist."
                continue
            }
            Resolve-TaskDependencies -TaskKey $depKey
        }

        $inStack.Remove($TaskKey)
        $visited[$TaskKey] = $true
        $order.Add($TaskKey)
    }

    foreach ($startTask in $startTasks) {
        Resolve-TaskDependencies -TaskKey $startTask
    }

    if ($plan.ValidationErrors.Count -gt 0) {
        $plan.IsValid = $false
        return $plan
    }

    $plan.ExecutionOrder = $order.ToArray()

    # Filter TaskMap and Tasks to only include tasks in the execution order
    $reachableKeys = [System.Collections.Generic.HashSet[string]]::new($plan.ExecutionOrder)
    foreach ($key in @($plan.TaskMap.Keys)) {
        if (-not $reachableKeys.Contains($key)) {
            $plan.TaskMap.Remove($key)
        }
    }
    $plan.Tasks = @($plan.TaskMap.Values)

    $plan.IsValid = $true

    Write-Debug "Build plan compiled: $($plan.ExecutionOrder.Count) tasks in execution order: $($plan.ExecutionOrder -join ' -> ')"
    return $plan
}
