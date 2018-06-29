If you call Psake but do not specify a build file, Psake will instead use a default build file name.  The example below run the default task in the default build file:

```powershell
Import-Module .\psake.psml
Invoke-psake
```

### What is the default build file called?

Previously the default build file name was called `default.ps1` however Psake will now prefer to use a file called `psakefile.ps1`

### Why the change?

One of Psake's main benefits is making it easier to find and execute build tasks, however the default build file name of `default.ps1` was not very descriptive.  Instead psake now uses `psakefile.ps1` as default, which clearly describes the file's intention.

### But what about my old default build files?

Psake will continue to use `default.ps1`.  However if both a `default.ps1` and `psakefile.ps1` file are detected, it will prefer the newer `psakefile.ps1` file.

Note that a Psake outputs a warning about using the older `default.ps1` file.
