# Releases

psake is made available across several different repositories including
Chocolatey, nuget, and PowerShell Gallery. The process to build the different
packages differs and this document is meant to capture the nuance of those
processes.

## Chocolatey

Chocolatey packages are similar to NuGet in that they require a nuspec file.

Chocolatey is one of the
[preinstalled software](https://github.com/actions/runner-images/blob/main/images/windows/Windows2022-Readme.md#installed-software)
on the Windows image. This makes it easier for us to be able to pack and push
our latest release.

At a high level, creating the package should take the following steps:

1. Copy the necessary files (.\build\nuget)
2. Update the version in the nuspec.
3. Choco pack
4. Set our API key
5. Choco push

Because we use psake for our builds (woohoo!) we can use the Task `BuildNuget`
to handle putting the files in place.

We can then use the `PublishChocolatey` function to `choco pack` and
`choco push`.

## PowerShell Module

To Publish a PowerShell module package we just need to run the `Publish-Module`
command when the module has been staged.

We can do this by running the `PublishPSGallery` task.
