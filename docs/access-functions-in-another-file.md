Use the *include* function to access functions that are in another script file.

The following is an example:

```powershell
Include ".\build_utils.ps1"

Task default -depends Test

Task Test -depends Compile, Clean {
}

Task Compile -depends Clean {
}

Task Clean {
}
```

You can have more than 1 include file in your script if you need to include multiple script files.