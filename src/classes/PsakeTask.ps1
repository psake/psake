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
    [string]$ErrorMessage
    [string]$ErrorDetail
    [string]$ErrorFormatted
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
        [string]$ErrorFormatted
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
        }
    }
    #endregion Constructors
}
