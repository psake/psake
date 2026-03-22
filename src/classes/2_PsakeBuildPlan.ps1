class PsakeBuildPlan {
    [string]$BuildFile
    [PsakeTask[]]$Tasks
    [string[]]$ExecutionOrder
    [hashtable]$TaskMap = @{}
    [hashtable]$InputHashes = @{}
    [bool]$IsValid = $false
    [string[]]$ValidationErrors = @()
    [datetime]$CompiledAt
    [string]$CacheDir
}
