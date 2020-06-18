function WriteTaskTimeSummary($invokePsakeDuration) {
    if ($psake.context.count -gt 0) {
        $currentContext = $psake.context.Peek()
        WriteOutput ("-" * 70)
        WriteOutput "Build Time Report"
        WriteOutput ("-" * 70)
        $list = @()
        while ($currentContext.executedTasks.Count -gt 0) {
            $taskKey = $currentContext.executedTasks.Pop()
            $task = $currentContext.tasks.$taskKey
            if ($taskKey -eq "default") {
                continue
            }
            $list += new-object PSObject -property @{
                Name = $task.Name;
                Duration = $task.Duration.ToString("hh\:mm\:ss\.fff")
            }
        }
        [Array]::Reverse($list)
        $list += new-object PSObject -property @{
            Name = "Total:";
            Duration = $invokePsakeDuration.ToString("hh\:mm\:ss\.fff")
        }
        # using "out-string | where-object" to filter out the blank line that format-table prepends
        $list | format-table -autoSize -property Name,Duration | out-string -stream | where-object { $_ } | WriteOutput
    }
}
