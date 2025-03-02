function Get-TasksFromContext {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentContext
    )

    $docs = $CurrentContext.tasks.Keys | ForEach-Object {
        $task = $CurrentContext.tasks.$_
        New-Object PSObject -Property @{
            Name        = $task.Name
            Alias       = $task.Alias
            Description = $task.Description
            DependsOn   = $task.DependsOn
        }
    }

    return $docs
}
