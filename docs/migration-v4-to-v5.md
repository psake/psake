# Migrating from psake v4 to v5

## Quick Start

Most v4 build scripts work in v5 without changes. The main breaking changes are:

1. **`default.ps1` is no longer auto-detected** — rename to `psakefile.ps1`
2. **`psake.ps1` / `psake.cmd` are removed** — use `Import-Module psake; Invoke-psake`
3. **.NET Framework < 4.0 is no longer supported** — update `Framework` calls
4. **`$framework` global variable is removed** — use `Framework '4.7.2'` function

## New Declarative Syntax

### Before (v4)
```powershell
Task Build -Depends Clean -Action {
    dotnet build -c $Configuration
}
```

### After (v5 — both syntaxes work)
```powershell
# New declarative style
Task 'Build' @{
    DependsOn = 'Clean'
    Action    = { dotnet build -c $Configuration }
}

# Old style still works
Task Build -Depends Clean -Action {
    dotnet build -c $Configuration
}
```

## Adding Caching with Inputs/Outputs

```powershell
Task 'Build' @{
    DependsOn = 'Clean'
    Inputs    = 'src/**/*.cs', 'src/**/*.csproj'
    Outputs   = 'bin/**/*.dll'
    Action    = { dotnet build -c $Configuration }
}
```

When the task runs, psake computes a SHA256 hash of all input files plus the Action scriptblock text. On subsequent runs, if the hash matches and output files exist, the task is skipped.

Use `Clear-PsakeCache` to force a full rebuild, or `Invoke-psake -NoCache`.

## Structured Output

`Invoke-psake` now returns a `PsakeBuildResult`:

```powershell
$result = Invoke-psake -BuildFile ./psakefile.ps1 -Quiet
$result.Success          # $true / $false
$result.Duration         # TimeSpan
$result.Tasks            # PsakeTaskResult[] with Name, Status, Duration, Cached
$result.ErrorMessage     # Error details if failed
```

For CI, use JSON output:
```powershell
Invoke-psake -OutputFormat JSON
```

## Version Declaration

Pin your build script to psake v5:
```powershell
Version 5

Task 'default' -depends 'Build'
Task 'Build' { dotnet build }
```

## Hashtable Properties

```powershell
# New style
Properties @{
    Configuration = 'Release'
    OutputDir     = './artifacts'
}

# Old style still works
Properties {
    $Configuration = 'Release'
    $OutputDir     = './artifacts'
}
```

## Testing Your Build Scripts

### Inspect the Build Plan
```powershell
$plan = Get-PsakeBuildPlan -BuildFile './psakefile.ps1'
$plan.ExecutionOrder    # ['clean', 'build', 'test', 'default']
$plan.TaskMap['build'].DependsOn  # ['Clean']
$plan.IsValid           # $true
$plan.ValidationErrors  # @()
```

### Test a Task in Isolation
```powershell
$result = Test-PsakeTask -BuildFile './psakefile.ps1' -TaskName 'Build' -Variables @{
    Configuration = 'Debug'
}
$result.Status    # 'Executed'
$result.Duration  # TimeSpan
```

## Backward Compatibility

The `$psake.build_success` variable is still set after each build, so existing CI scripts like:
```powershell
Invoke-psake
if (!$psake.build_success) { exit 1 }
```
continue to work without changes.
