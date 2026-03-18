class PsakeTask {
    #region Properties
    [string]$Name
    [string[]]$DependsOn
    [scriptblock]$PreAction
    [scriptblock]$Action
    [scriptblock]$PostAction
    [scriptblock]$PreCondition
    [scriptblock]$PostCondition
    [bool]$ContinueOnError = $False
    [string]$Description
    [System.TimeSpan]$Duration = [System.TimeSpan]::Zero
    [string[]]$RequiredVariables
    [string]$Alias
    [bool]$Success = $true # let's be optimistic
    [bool]$Executed = $false
    [string]$ErrorMessage
    [string]$ErrorDetail
    [string]$ErrorFormatted
    [object[]]$Output
    #endregion Properties

    #region Constructors
    PsakeTask(
        [string]$Name,
        [string[]]$DependsOn,
        [scriptblock]$PreAction,
        [scriptblock]$Action,
        [scriptblock]$PostAction,
        [scriptblock]$PreCondition,
        [scriptblock]$PostCondition,
        [bool]$ContinueOnError,
        [string]$Description,
        [System.TimeSpan]$Duration,
        [string[]]$RequiredVariables,
        [string]$Alias,
        [bool]$Success,
        [string]$ErrorMessage,
        [string]$ErrorDetail,
        [string]$ErrorFormatted,
        [object[]]$Output
    ) {
        $this.Name = $Name
        $this.DependsOn = $DependsOn
        $this.PreAction = $PreAction
        $this.Action = $Action
        $this.PostAction = $PostAction
        $this.PreCondition = $PreCondition
        $this.PostCondition = $PostCondition
        $this.ContinueOnError = $ContinueOnError
        $this.Description = $Description
        $this.Duration = $Duration
        $this.RequiredVariables = $RequiredVariables
        $this.Alias = $Alias
        $this.Success = $Success
        $this.ErrorMessage = $ErrorMessage
        $this.ErrorDetail = $ErrorDetail
        $this.ErrorFormatted = $ErrorFormatted
        $this.Output = $Output
    }

    PsakeTask(
        [hashtable]$Hashtable
    ) {
        switch ($Hashtable.Keys) {
            'Name' { $this.Name = $Hashtable.Name }
            'DependsOn' { $this.DependsOn = $Hashtable.DependsOn }
            'PreAction' { $this.PreAction = $Hashtable.PreAction }
            'Action' { $this.Action = $Hashtable.Action }
            'PostAction' { $this.PostAction = $Hashtable.PostAction }
            'PreCondition' { $this.PreCondition = $Hashtable.PreCondition }
            'PostCondition' { $this.PostCondition = $Hashtable.PostCondition }
            'ContinueOnError' { $this.ContinueOnError = $Hashtable.ContinueOnError }
            'Description' { $this.Description = $Hashtable.Description }
            'Duration' { $this.Duration = $Hashtable.Duration }
            'RequiredVariables' { $this.RequiredVariables = $Hashtable.RequiredVariables }
            'Alias' { $this.Alias = $Hashtable.Alias }
            'Success' { $this.Success = $Hashtable.Success }
            'ErrorMessage' { $this.ErrorMessage = $Hashtable.ErrorMessage }
            'ErrorDetail' { $this.ErrorDetail = $Hashtable.ErrorDetail }
            'ErrorFormatted' { $this.ErrorFormatted = $Hashtable.ErrorFormatted }
            'Output' { $this.Output = $Hashtable.Output }
        }
    }
    #endregion Constructors

    #region Methods
    [bool] RecursiveSuccess([PsakeTask[]]$TaskList) {
        if ($this.DependsOn.Count -ne 0) {
            # Recurse down each dependency and check for any false
            foreach ($dependant in $this.DependsOn) {
                $dependentTask = $TaskList | Where-Object { $_.Name -eq $dependant }
                # If dependency isn't in the task list, we'll consider that a
                # failure (since it can't be executed successfully)
                if ($null -eq $dependentTask) {
                    return $false
                }
                if (-not $dependentTask.RecursiveSuccess($TaskList)) {
                    return $false
                }
            }
        }
        return $this.Success -and $this.Executed
    }
    #endregion Methods
}
