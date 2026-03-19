function Get-InputHash {
    <#
    .SYNOPSIS
    Computes a SHA256 hash over a task's inputs for caching.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PsakeTask]$Task,

        [Parameter(Mandatory = $true)]
        [PsakeBuildPlan]$Plan
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashInput = [System.Text.StringBuilder]::new()

    # Hash the Action scriptblock text
    if ($Task.Action) {
        $null = $hashInput.AppendLine($Task.Action.ToString())
    }

    # Hash the Inputs spec itself when it's a scriptblock (code changes invalidate cache)
    if ($Task.Inputs -is [scriptblock]) {
        $null = $hashInput.AppendLine("inputs-script:$($Task.Inputs.ToString())")
    }

    # Hash sorted input file contents
    $inputFiles = Resolve-TaskFiles -FileSpec $Task.Inputs | Sort-Object
    foreach ($file in $inputFiles) {
        if (Test-Path $file -PathType Leaf) {
            $fileBytes = [System.IO.File]::ReadAllBytes($file)
            $fileHash = [System.BitConverter]::ToString($sha256.ComputeHash($fileBytes)).Replace('-', '')
            $null = $hashInput.AppendLine("$file`:$fileHash")
        }
    }

    # Hash dependency task hashes (cascade invalidation)
    foreach ($dep in $Task.DependsOn) {
        $depKey = $dep.ToLower()
        if ($Plan.InputHashes.ContainsKey($depKey)) {
            $null = $hashInput.AppendLine("dep:$depKey`:$($Plan.InputHashes[$depKey])")
        }
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashInput.ToString())
    $hash = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-', '')
    $sha256.Dispose()

    return "sha256:$hash"
}
