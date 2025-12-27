# Troubleshooting psake

Common issues and solutions when using psake build automation.

## PSScriptAnalyzer Warnings

### PSUseDeclaredVarsMoreThanAssignments in Properties Blocks

**Symptom:** PSScriptAnalyzer reports warnings like:

```
PSUseDeclaredVarsMoreThanAssignments: The variable 'x' is assigned but never used.
```

**Cause:** PSScriptAnalyzer performs static code analysis and cannot detect that psake dot-sources Properties scriptblocks into task execution scope at runtime. The variables ARE used, but static analysis can't see the dynamic scoping.

#### Solution 1 - Recommended: Use Script-Scoped Variables

The simplest and most effective solution is to use script-scoped variables in your Properties blocks:

```powershell
Properties {
    $script:build_dir = "c:\build"
    $script:config = "Release"
    $script:connection_string = "datasource=localhost;..."
}

Task Compile {
    "Building to $build_dir in $config mode"
}
```

**Benefits:**
- No functional difference at runtime
- Eliminates PSScriptAnalyzer warnings
- No configuration changes needed
- Works with all PSScriptAnalyzer versions

#### Solution 2: Configure PSScriptAnalyzer Settings

If you prefer to keep the simpler syntax without the `$script:` prefix, create a PSScriptAnalyzer settings file in your project root:

**File: `.pssasettings.psd1` or `PSScriptAnalyzerSettings.psd1`**

```powershell
@{
    # Disable the rule for build scripts
    ExcludeRules = @('PSUseDeclaredVarsMoreThanAssignments')
}
```

**Alternative:** Exclude only specific files by using a custom script:

```powershell
@{
    # Include all rules by default
    IncludeRules = @('*')

    # Exclude specific paths (adjust pattern to match your build scripts)
    ExcludeRules = @()
}
```

**Note:** Per-variable suppression using `[Diagnostics.CodeAnalysis.SuppressMessageAttribute]` doesn't work for variables due to a [known PSScriptAnalyzer limitation](https://github.com/PowerShell/PSScriptAnalyzer/issues/2040).

**Drawback:** Disabling the rule entirely means you'll lose warnings for genuinely unused variables in your build script.

### Understanding How psake Properties Work

To better understand why this warning occurs, it helps to know how psake processes Properties blocks:

1. **Collection Phase:** The `Properties` function stores scriptblocks in a stack during build file parsing
2. **Execution Phase:** `Invoke-psake` dot-sources these scriptblocks into the parent scope (see [src/public/Invoke-psake.ps1:306-311](../src/public/Invoke-psake.ps1#L306-L311))
3. **Availability:** Variables become available to tasks, BuildSetup, BuildTearDown, and other build blocks through dynamic scoping
4. **Static Analysis Limitation:** PSScriptAnalyzer analyzes code without executing it, so it can't detect this runtime scoping behavior

For more details, run:

```powershell
Get-Help Properties -Full
```

## Other Common Issues

### Module Import Errors

**Symptom:** `Import-Module : The specified module 'psake' was not loaded because no valid module file was found`

**Solution:** Ensure psake is installed correctly:

```powershell
# Check if psake is installed
Get-Module -ListAvailable psake

# If not installed, install from PowerShell Gallery
Install-Module -Name psake -Scope CurrentUser

# Import the module
Import-Module psake
```

### Execution Policy Errors

**Symptom:** `File cannot be loaded because running scripts is disabled on this system`

**Solution:** Set the execution policy to allow script execution:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Task Not Found Errors

**Symptom:** `Error: Task [TaskName] was not found in the build script`

**Solution:**
- Verify the task name is spelled correctly (task names are case-sensitive)
- Ensure the task is defined before being referenced in `-Depends`
- Check that you're running the correct build script file

### Properties Not Available in Tasks

**Symptom:** Variables defined in Properties blocks are `$null` or undefined in tasks

**Common Causes:**
1. **Scope issue:** Using `Set-Variable` with explicit scopes can interfere with psake's scoping
2. **Timing issue:** Trying to access properties before the Properties block executes
3. **Include order:** If using `Include`, ensure Properties are defined before tasks that use them

**Solution:**
- Use simple variable assignments in Properties blocks: `$var = "value"`
- Avoid using `Set-Variable` with `-Scope` parameter
- Define Properties before tasks in your build script
- If using multiple Properties blocks, they're executed in the order defined

### Framework Version Issues

**Symptom:** `Error: No .NET Framework installation directory found`

**Solution:** Specify the framework version explicitly:

```powershell
Framework "4.8"

Properties {
    # ...
}
```

Or when invoking psake:

```powershell
Invoke-psake -framework "4.8"
```

## Getting More Help

- **Documentation:** See the [psake docs](https://psake.dev/docs/intro)
- **Built-in Help:** Run `Get-Help Invoke-psake -Full` or `Get-Help <function-name> -Full`
- **Examples:** Check the `examples` directory for sample build scripts
- **Issues:** Report bugs or request features at [https://github.com/psake/psake/issues](https://github.com/psake/psake/issues)
- **Discussions:** Ask questions in [GitHub Discussions](https://github.com/psake/psake/discussions)

## Contributing

Found a solution to a common problem? Consider contributing to this troubleshooting guide by [opening a pull request](https://github.com/psake/psake/pulls).
