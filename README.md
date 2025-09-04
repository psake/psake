# psake

<center><img src="https://github.com/psake/graphics/blob/master/png/psake-single-icon-olive-128x128.png?raw=true" alt="psake icon"></center>

A build automation tool written in PowerShell that leverages your existing
command-line knowledge.

[![GitHub Actions Status][github-actions-badge]][github-actions-build]
[![PowerShell Gallery][psgallery-badge]][psgallery]
[![Chocolatey][chocolatey-badge]][chocolatey]
[![Nuget downloads][nuget-downloads]][nuget]
![Open Collective backers and sponsors](https://img.shields.io/opencollective/all/psake)
[![Crowdin](https://badges.crowdin.net/psake/localized.svg)](https://crowdin.com/project/psake)

## What is psake?

psake is a build automation tool written in PowerShell. It avoids the
angle-bracket tax associated with executable XML by leveraging the PowerShell
syntax in your build scripts. psake has a syntax inspired by rake (aka make
in Ruby) and bake (aka make in Boo), but is easier to script because it
leverages your existing command-line knowledge.

> **Note:** psake is pronounced "sake" – as in Japanese rice wine. It does
> NOT rhyme with make, bake, or rake.

## Installation

psake can be installed in several ways:

### Option 1: PowerShell Gallery (Recommended)

```powershell
Install-Module -Name psake -Scope CurrentUser
```

### Option 2: Chocolatey

```powershell
choco install psake
```

### Option 3: Manual Installation

1. Download and extract the project from the
   [releases page](https://github.com/psake/psake/releases)
2. Unblock the zip file before extracting (right-click → Properties → Unblock)
3. Import the module:

   ```powershell
   Import-Module .\psake.psm1
   ```

## Quick Start

### Prerequisites

- PowerShell 5.1 or later
- Execution policy set to allow script execution:

  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Your First Build Script

We highly recommend reading the [psake docs](https://psake.dev/docs/intro) for a
more thorough walk through.

1. Create a build script file (e.g., `psakefile.ps1`):

   ```powershell
   Task Default -Depends Test, Package

   Task Test {
       Write-Host "Running tests..."
   }

   Task Package {
       Write-Host "Creating package..."
   }
   ```

2. Run the build:

   ```powershell
   Invoke-psake
   ```

### Running Examples

Navigate to the examples directory and try out the sample build scripts:

```powershell
cd .\examples
Invoke-psake                    # Runs the default task
Invoke-psake .\psakefile.ps1 Clean  # Runs the Clean task
```

## Getting Help

Get detailed help and examples:

```powershell
Get-Help Invoke-psake -Full
```

## Visual Studio Integration

For Visual Studio 2017 and later, psake can automatically locate MSBuild.
If you encounter issues, you may need to install the
[VSSetup PowerShell module](https://www.powershellgallery.com/packages/VSSetup):

```powershell
Install-Module -Name VSSetup -Scope CurrentUser
```

## Release Notes

You can find information about each release of psake in the
[releases section](https://github.com/psake/psake/releases) and the
[Changelog](CHANGELOG.md).

## Contributing

We welcome contributions! Here's how you can get involved:

### Community

- [GitHub Discussions](https://github.com/orgs/psake/discussions) - Ask
  questions and share ideas
- [PowerShell Discord](https://aka.ms/psdiscord) - Join the #psake channel
- [PowerShell Slack](https://aka.ms/psslack) - Join the #psake channel

### Development

- Fork the [main repository](https://github.com/psake/psake) and submit
  pull requests
- Check out the [psake docs](http://github.com/psake/docs) for documentation
- Browse the [issues list](http://github.com/psake/psake/issues) for bugs
  and feature requests
- Explore [psake-contrib](http://github.com/psake/psake-contrib) for
  additional scripts and modules

## License

psake is released under the [MIT license](http://www.opensource.org/licenses/MIT).

[github-actions-badge]: https://github.com/psake/psake/workflows/CI/badge.svg
[github-actions-build]: https://github.com/psake/psake/actions
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/psake.svg?label=PowerShell%20Gallery%20Downloads
[psgallery]: https://www.powershellgallery.com/packages/psake
[chocolatey-badge]: https://img.shields.io/chocolatey/dt/psake.svg?logo=chocolatey
[chocolatey]: https://chocolatey.org/packages/psake
[nuget-downloads]: https://img.shields.io/nuget/dt/psake.svg?logo=nuget
[nuget]: https://www.nuget.org/packages/psake/

