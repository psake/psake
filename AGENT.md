# AGENT.md — psake Development Guide

> **Keep this file up to date.** When adding new features, exported functions, configuration options, or changing architectural patterns, update the relevant sections of this document.

## What is psake?

psake (pronounced "sah-keh") is a build automation tool written in PowerShell. It uses PowerShell syntax instead of XML, inspired by Ruby's Rake. The module is published to the PowerShell Gallery, Chocolatey, and NuGet.

- **Current version:** 4.9.1
- **Minimum PowerShell version:** 3.0
- **License:** MIT

## psake Organization Ecosystem

### [psake/psake](https://github.com/psake/psake) (this repo)

The core module. Contains the build engine, exported functions, task/property system, and all tests.

### [psake/docs](https://github.com/psake/docs)

The documentation website (psake.dev). Contains the MkDocs site **and a copy of the generated cmdlet reference docs from this repo**. When you update comment-based help on exported functions here, the markdown help must be regenerated (`./build.ps1 -Task CreateMarkdownHelp`) and the output copied to the docs repo. The two repos are not automatically synced — docs must be updated manually after changes.

### [psake/psake-contrib](https://github.com/psake/psake-contrib)

Community-contributed scripts, helper functions, and modules that extend psake. These are separate from the core module and are not required for psake to function.

### [psake/graphics](https://github.com/psake/graphics)

Logo assets and branding materials for psake.

## Repository Structure

```
psake/
├── src/                        # Module source code
│   ├── psake.psm1              # Module loader — dot-sources everything, initializes $psake
│   ├── psake.psd1              # Module manifest
│   ├── psake.ps1               # Standalone runner script
│   ├── psake.cmd               # Windows batch wrapper
│   ├── psake-config.ps1        # Configuration defaults template
│   ├── classes/PsakeTask.ps1   # The PsakeTask class definition
│   ├── enums/OutputTypes.ps1   # Output type enumeration
│   ├── public/                 # Exported functions (see below)
│   ├── private/                # Internal helper functions
│   └── en-US/, es-US/          # Localization data files
├── build.ps1                   # Repo build script (uses Invoke-Step, NOT psake itself)
├── requirements.psd1           # PSDepend build dependencies
├── tests/                      # Pester unit tests
├── specs/                      # Integration test build scripts (70+ scenarios)
├── examples/                   # Example build scripts for users
├── docs/                       # Local docs (also see psake/docs repo)
├── l10n/                       # YAML localization source files
├── tabexpansion/               # PowerShell tab completion
└── .github/workflows/          # CI (GitHub Actions) — tests on Windows, Ubuntu, macOS
```

## Exported Functions

| Function | Purpose |
|---|---|
| `Invoke-psake` | Main entry point — runs a build script |
| `Invoke-Task` | Execute a task by name from within another task |
| `Get-PSakeScriptTasks` | Introspect tasks defined in a build script |
| `Task` | Define a build task |
| `Properties` | Define shared variables accessible to all tasks |
| `Include` | Dot-source an external file into build scope |
| `FormatTaskName` | Customize the task execution header |
| `TaskSetup` / `TaskTearDown` | Hooks that run before/after each task |
| `BuildSetup` / `BuildTearDown` | Hooks that run once at build start/end |
| `Framework` | Select a .NET Framework version |
| `Assert` | Throw if a condition is false |
| `Exec` | Run an external command and assert success |

The module also exports the `$psake` global variable (a hashtable with build state).

## Critical Architecture: Script Scope Execution

**This is the single most important thing to understand about psake's internals.**

### How it works

All task code, property blocks, and included files run in **the same script scope** — the scope of `Invoke-InBuildFileScope`. The chain is:

1. `Invoke-psake` calls `Invoke-InBuildFileScope`, which **dot-sources** the build file (`. $psake.build_script_file.FullName`)
2. The build file's `Task`, `Properties`, `Include`, etc. calls register definitions into the context
3. `Properties` blocks are **popped off a stack and dot-sourced** (`. $propertyBlock`) into the execution scope
4. `Include` files are **dot-sourced** (`. $includeFilename`) after the build file loads
5. Tasks execute their `Action` scriptblocks via `& $task.Action` in that same scope

### Ramifications

**Variables leak between tasks.** Because all tasks share the same scope, a variable set in one task is visible in later tasks. This is by design — it allows `Properties` blocks to define shared state — but it means:

- A task can accidentally overwrite a variable that a later task depends on
- There is no isolation between tasks; order of execution matters
- `$script:` scoped variables in a build file refer to the build file's scope (which is the execution scope)
- You cannot rely on a variable being "unset" just because the current task didn't define it — a prior task or property block may have

**`$script:` prefix in Properties blocks is cosmetic at runtime.** Using `$script:build_dir` vs `$build_dir` inside a `Properties` block has no functional difference — both are dot-sourced into the same scope. The `$script:` prefix exists solely to satisfy PSScriptAnalyzer's `PSUseDeclaredVarsMoreThanAssignments` rule, which cannot see across dot-source boundaries.

**Parameters vs Properties have different injection timing:**
- `-Parameters` are injected **before** `Properties` blocks run (so Properties can reference them)
- `-Properties` are injected **after** `Properties` blocks run (so they override Properties values)
- Both use `Set-Variable` / `New-Item variable:\` to inject into the current scope

**Included files share scope.** Files loaded via `Include` are dot-sourced into the same scope, so functions and variables defined in included files are available to all tasks. This enables code sharing but also means name collisions between includes are silent.

**Nested builds get their own context.** `Invoke-psake` pushes a new context onto `$psake.Context` (a `Stack`), so nested builds have isolated task registrations and state. The context is popped when the nested build completes. However, the `$psake` variable itself is global.

**Circular dependency detection uses a call stack.** `Invoke-Task` pushes task names onto `$currentContext.callStack` before recursing into dependencies and pops them after. If a task is already on the stack, it throws.

### Why this matters for contributors

When modifying the engine:
- Never assume a variable is "local" to a task unless it's declared with `$local:` or inside a function body
- Be careful adding new variables in `Invoke-InBuildFileScope` or `Invoke-psake`'s scriptblock — they become visible to user tasks
- Test property/parameter injection order carefully — `-Parameters` before dot-sourcing, `-Properties` after
- Remember that `& $scriptblock` creates a child scope but `. $scriptblock` does not — psake uses dot-sourcing deliberately

## Build & Test

The repo's own build script (`build.ps1`) does **not** use psake — it uses a custom `Invoke-Step` system with `[DependsOn]` attributes. This avoids bootstrapping issues.

```powershell
# Bootstrap dependencies and run tests (what CI does)
./build.ps1 -Task Test -Bootstrap

# Run just Pester tests (after bootstrap)
./build.ps1 -Task Pester

# Run PSScriptAnalyzer
./build.ps1 -Task Analyze

# Build the module to output/
./build.ps1 -Task Build

# Regenerate cmdlet markdown help (for docs repo)
./build.ps1 -Task CreateMarkdownHelp
```

**Dependencies** (installed by `-Bootstrap`):
- Pester 5.6.1
- PSScriptAnalyzer 1.19.1
- PlatyPS 0.14.1
- BuildHelpers 2.0.16

**CI** runs on GitHub Actions across Windows, Ubuntu, and macOS with `./build.ps1 -Task Test -Bootstrap`.

## Testing

- **Unit tests** are in `tests/` and use Pester 5. They validate the manifest, help content, and code quality.
- **Integration tests** are in `specs/`. Each `.ps1` file is a standalone psake build script that exercises a specific feature (dependencies, properties, error handling, framework selection, shared tasks, etc.). The test runner in `tests/integration/spec.tests.ps1` invokes each spec file with `Invoke-psake` and checks for success/failure.
- When adding a new feature, add both a spec file demonstrating the feature and any necessary Pester tests.

## Localization

Localized strings live in `l10n/*.yml` (YAML source of truth). The build task `ConvertFromLocalizationYaml` converts these to:
- `src/<locale>/Messages.psd1` files
- An inline `data msgs { ... }` block in `src/psake.psm1` (workaround for a PowerShell bug)

When adding or modifying error/warning messages, edit the YAML files and run the conversion task — do not edit the generated `.psd1` or inline data block directly.

## Configuration System

psake configuration is layered:
1. **Defaults** — hardcoded in `psake.psm1` (`$psake.ConfigDefault`)
2. **Module-level** — `psake-config.ps1` next to `psake.psm1`
3. **Build-level** — `psake-config.ps1` next to the build script (highest priority)

Key configuration options: `buildFileName`, `framework`, `taskNameFormat`, `verboseError`, `coloredOutput`, `modules`, `moduleScope`, `outputHandler`, `outputHandlers`.

## Conventions

- Public functions go in `src/public/`, private functions in `src/private/`
- One function per file, filename matches function name
- Use comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`) on all public functions
- Follow existing PowerShell style: `PascalCase` for function names, `camelCase` for local variables
- All exported functions must be listed in `psake.psd1` `FunctionsToExport`
- The module loader (`psake.psm1`) auto-discovers files via `Get-ChildItem` — no manual imports needed for new function files

## Keeping This Document Current

When you make changes to psake, update this file:

- **New exported function?** Add it to the Exported Functions table and update the description
- **New configuration option?** Document it in the Configuration System section
- **Changed scope/execution model?** Update the Script Scope Execution section
- **New build task?** Update Build & Test section
- **New repo in the org?** Add it to the Ecosystem section
- **New test pattern?** Document it in the Testing section
