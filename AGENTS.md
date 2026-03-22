# AGENT.md — psake Development Guide

> **Keep this file up to date.** When adding new features, exported functions, configuration options, or changing architectural patterns, update the relevant sections of this document.

## What is psake?

psake (pronounced "sah-keh") is a build automation tool written in PowerShell. It uses PowerShell syntax instead of XML, inspired by Ruby's Rake. The module is published to the PowerShell Gallery, Chocolatey, and NuGet.

- **Current version:** 5.0.0
- **Minimum PowerShell version:** 5.1
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
│   ├── psake-config.ps1        # Configuration defaults template
│   ├── classes/
│   │   ├── PsakeTask.ps1       # Task class with Inputs/Outputs/Cached properties
│   │   ├── PsakeBuildPlan.ps1  # Compile-phase build plan
│   │   └── PsakeBuildResult.ps1 # Structured build result
│   ├── enums/OutputTypes.ps1   # Output type and format enumerations
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
| `Invoke-psake` | Main entry point — runs a build script (two-phase compile/run) |
| `Invoke-Task` | Execute a task by name from within another task |
| `Get-PSakeScriptTasks` | Introspect tasks defined in a build script |
| `Get-PsakeBuildPlan` | Compile a build file and return the plan without executing (testability API) |
| `Test-PsakeTask` | Run a single task in isolation without dependencies (testability API) |
| `Task` | Define a build task (supports both legacy and declarative hashtable syntax) |
| `Properties` | Define shared variables (supports both scriptblock and hashtable syntax) |
| `Include` | Dot-source an external file into build scope |
| `FormatTaskName` | Customize the task execution header |
| `TaskSetup` / `TaskTearDown` | Hooks that run before/after each task |
| `BuildSetup` / `BuildTearDown` | Hooks that run once at build start/end |
| `Framework` | Select a .NET Framework version (4.0+) |
| `Assert` | Throw if a condition is false |
| `Exec` | Run an external command and assert success |
| `Version` | Declare the required psake version for the build script |
| `Clear-PsakeCache` | Clear the local file-based task cache |

The module also exports the `$psake` global variable (a hashtable with build state).

## v5 Architecture: Two-Phase Compile/Run Model

psake v5 uses a two-phase model inspired by Pester v5's Discovery/Run pattern:

### Compile Phase

1. `Invoke-psake` calls `Invoke-InBuildFileScope`, which **dot-sources** the build file
2. The build file's `Task`, `Properties`, `Include`, `Version` calls register definitions into the context
3. `Compile-BuildPlan` validates the dependency graph via topological sort
4. Circular dependencies and missing task references are detected **before** any task executes
5. Input hashes are computed for cacheable tasks
6. Returns a `PsakeBuildPlan` object

### Run Phase

1. `Invoke-BuildPlan` executes tasks in the pre-computed order
2. For each task: check cache → check precondition → run setup → execute action → run teardown → update cache
3. Returns a `PsakeBuildResult` with structured per-task results

### Declarative Task Syntax (v5)

```powershell
Task 'Build' @{
    DependsOn = 'Clean'
    Inputs    = 'src/**/*.cs'
    Outputs   = 'bin/**/*.dll'
    Action    = { dotnet build }
}
```

The legacy syntax `Task 'Build' -Depends 'Clean' -Action { dotnet build }` continues to work.

### Local File-Based Caching

Tasks with `Inputs` and `Outputs` are content-addressed cached in `.psake/cache/`. A task is skipped when its input hash matches the cached hash and output files exist.

### Structured Output

`Invoke-psake` returns a `PsakeBuildResult` object with `Success`, `Duration`, `Tasks` (per-task results), and `ErrorMessage`. Use `-OutputFormat JSON` for CI integration.

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

**Variables leak between tasks.** Because all tasks share the same scope, a variable set in one task is visible in later tasks. This is by design — it allows `Properties` blocks to define shared state.

**Parameters vs Properties have different injection timing:**

- `-Parameters` are injected **before** `Properties` blocks run (so Properties can reference them)
- `-Properties` are injected **after** `Properties` blocks run (so they override Properties values)

**Nested builds get their own context.** `Invoke-psake` pushes a new context onto `$psake.Context` (a `Stack`), so nested builds have isolated task registrations and state.

## Build & Test

The repo dogfoods psake: `build.ps1` is a thin bootstrapper that
installs the **published** psake 4.9.1 from PSGallery, then calls
`Invoke-psake` on `psakefile.ps1`. The dev module (5.0.0) is what
gets built and tested.

**Bootstrapping caveat:** Tasks that import the dev module (Pester,
CreateMarkdownHelp) run in a **child process** to avoid clobbering
the orchestrating psake's `$psake` state variable.

```powershell
# Bootstrap dependencies and run tests (what CI does)
./build.ps1 -Task Test -Bootstrap

# Run just Pester tests (after bootstrap)
./build.ps1 -Task Pester

# Run PSScriptAnalyzer
./build.ps1 -Task Analyze

# Build the module to output/
./build.ps1 -Task Build

# Show available tasks
./build.ps1 -Docs
```

**Dependencies** (installed by `-Bootstrap` via PSDepend):

- psake 4.9.1 (build orchestration)
- Pester 5.6.1
- PSScriptAnalyzer 1.25.0
- PlatyPS 0.14.1
- BuildHelpers 2.0.16

**CI** runs on GitHub Actions across Windows, Ubuntu, and macOS
with `./build.ps1 -Task Test -Bootstrap`.

## Testing

- **Unit tests** are in `tests/` and use Pester 5. They validate the manifest, help content, code quality, and v5 features (compile phase, declarative syntax, structured output, testability APIs).
- **Integration tests** are in `specs/`. Each `.ps1` file is a standalone psake build script that exercises a specific feature. The test runner in `tests/integration/spec.tests.ps1` invokes each spec file with `Invoke-psake` and checks for success/failure.
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
