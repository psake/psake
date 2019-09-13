Welcome to the psake project
=============================

| Azure Pipelines | GitHub Actions | PS Gallery | Chocolatey | Nuget.org | Gitter |
|-----------------|----------------|------------|------------|-----------|--------|
[![Azure Pipelines Build Status][azure-pipeline-badge]][azure-pipeline-build] | [![GitHub Actions Status][github-actions-badge]][github-actions-build] | [![PowerShell Gallery][psgallery-badge]][psgallery] | [![Chocolatey][chocolatey-badge]][chocolatey] | [![Nuget downloads][nuget-downloads]][nuget] | [![Join the chat at https://gitter.im/psake/psake][gitter-badge]][gitter]

psake is a build automation tool written in PowerShell. It avoids the angle-bracket tax associated with executable XML by leveraging the PowerShell syntax in your build scripts.
psake has a syntax inspired by rake (aka make in Ruby) and bake (aka make in Boo), but is easier to script because it leverages your existing command-line knowledge.

psake is pronounced sake – as in Japanese rice wine. It does NOT rhyme with make, bake, or rake.

## How to get started

**Step 1:** Download and extract the project

You will need to "unblock" the zip file before extracting - PowerShell by default does not run files downloaded from the Internet.
Just right-click the zip and click on "properties" and click on the "unblock" button.

**Step 2:** CD into the directory where you extracted the project (where the psake.psm1 file is)

> Import-Module .\psake.psm1

If you encounter the following error "Import-Module : ...psake.psm1 cannot be loaded because the execution of scripts is disabled on this system." Please see "get-help about_signing" for more details.

1. Run PowerShell as administrator
2. Set-ExecutionPolicy RemoteSigned

> Get-Help Invoke-psake -Full
> - this will show you help and examples of how to use psake

**Step 3:** Run some examples

> CD .\examples
>
> Invoke-psake
> - This will execute the "default" task in the "psakefile.ps1"
>
> Invoke-psake .\psakefile.ps1 Clean
> - will execute the single task in the psakefile.ps1 script

**Step 4:** Set your PATH variable

If you wish to use the psake command from outside of the install folder, add the folder install directory to your PATH variable.

**Step 5: (With VS2017)** Install the VSSetup dependency

psake uses [VSSetup](https://blogs.msdn.microsoft.com/heaths/2017/01/25/visual-studio-setup-powershell-module-available/) to locate msbuild when using Visual Studio 2017.  The VSSetup PowerShell module must be installed prior to compiling a VS2017 project with psake.  Install instructions for VSSetup can be found [here](https://github.com/Microsoft/vssetup.powershell#installing) and [here](https://www.powershellgallery.com/packages/VSSetup).

## Release Notes

You can find all the information about each release of psake in the [releases section](https://github.com/psake/psake/releases).

## How To Contribute, Collaborate, Communicate

If you'd like to get involved with psake, we have discussion groups over at Google: **[psake-dev](http://groups.google.com/group/psake-dev)** **[psake-users](http://groups.google.com/group/psake-users)**

Anyone can fork the main repository and submit patches, as well. And lastly, the [wiki](http://wiki.github.com/psake/psake/) and [issues list](http://github.com/psake/psake/issues) are also open for additions, edits, and discussion.

Also check out the **[psake-contrib](http://github.com/psake/psake-contrib)** project for scripts, modules and functions to help you with a build.

## License

psake is released under the [MIT license](http://www.opensource.org/licenses/MIT).

[azure-pipeline-badge]: https://dev.azure.com/devblackops/psake/_apis/build/status/psake.psake?branchName=master
[azure-pipeline-build]: https://dev.azure.com/devblackops/psake/_build/latest?definitionId=5&branchName=master
[github-actions-badge]: https://github.com/psake/psake/workflows/CI/badge.svg
[github-actions-build]: https://github.com/psake/psake/actions
[gitter-badge]: https://badges.gitter.im/Join%20Chat.svg
[gitter]: https://gitter.im/psake/psake?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[psgallery-badge]: https://img.shields.io/powershellgallery/dt/psake.svg
[psgallery]: https://www.powershellgallery.com/packages/psake
[chocolatey-badge]: https://img.shields.io/chocolatey/dt/psake.svg
[chocolatey]: https://chocolatey.org/packages/psake
[nuget-downloads]: https://img.shields.io/nuget/dt/psake.svg
[nuget]: https://www.nuget.org/packages/psake/
